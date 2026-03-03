import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class BiddingScreen extends StatefulWidget {
  final String tenderId;
  final String institutionName;
  final String itemName;
  final String quantity;

  const BiddingScreen({
    Key? key,
    required this.tenderId,
    required this.institutionName,
    required this.itemName,
    required this.quantity,
  }) : super(key: key);

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final TextEditingController _bidController = TextEditingController();
  final TextEditingController _kraController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingData = true;
  bool _isVerified = false;

  File? _tccImage;
  File? _kraImage; // 🔥 NEW: Holds the KRA Certificate photo

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _bidController.dispose();
    _kraController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final profile = await supabase
            .from('profiles')
            .select('is_verified, national_id, kra_pin')
            .eq('id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _isVerified = profile?['is_verified'] ?? false;
            if (profile?['national_id'] != null) {
              _idController.text = profile!['national_id'].toString();
            }
            if (profile?['kra_pin'] != null) {
              _kraController.text = profile!['kra_pin'].toString();
            }
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking verification: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // 🔥 NEW: Smart Image Picker that handles both documents
  Future<void> _pickImage(bool isKraDoc) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        if (isKraDoc) {
          _kraImage = File(pickedFile.path);
        } else {
          _tccImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitBid() async {
    final bidText = _bidController.text.trim();
    final kraText = _kraController.text.trim();
    final idText = _idController.text.trim();

    // Basic Validation
    if (bidText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your bid amount.')));
      return;
    }

    final bidAmount = double.tryParse(bidText);
    if (bidAmount == null || bidAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid bid amount.')));
      return;
    }

    // 🔥 NEW: Ultra-Strict KYC Validation
    if (!_isVerified) {
      if (idText.isEmpty ||
          kraText.isEmpty ||
          _tccImage == null ||
          _kraImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'National ID, KRA PIN, and BOTH document photos are mandatory.'),
              backgroundColor: Colors.orange),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) throw Exception('You must be logged in.');

      final existingBid = await supabase
          .from('bids')
          .select()
          .eq('tender_id', widget.tenderId)
          .eq('farmer_id', user.id)
          .maybeSingle();
      if (existingBid != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('You already bid on this!'),
              backgroundColor: Colors.orange));
          setState(() => _isSubmitting = false);
        }
        return;
      }

      // Handle Document Uploads if not verified
      if (!_isVerified) {
        // 1. Upload KRA Certificate
        final kraExt = _kraImage!.path.split('.').last;
        final kraFileName = '${user.id}_kra_cert.$kraExt';
        await supabase.storage.from('compliance_docs').upload(
            kraFileName, _kraImage!,
            fileOptions: const FileOptions(upsert: true));
        final kraUrl =
            supabase.storage.from('compliance_docs').getPublicUrl(kraFileName);

        // 2. Upload TCC
        final tccExt = _tccImage!.path.split('.').last;
        final tccFileName = '${user.id}_tcc.$tccExt';
        await supabase.storage.from('compliance_docs').upload(
            tccFileName, _tccImage!,
            fileOptions: const FileOptions(upsert: true));
        final tccUrl =
            supabase.storage.from('compliance_docs').getPublicUrl(tccFileName);

        // 3. Update profile
        await supabase.from('profiles').update({
          'national_id': idText,
          'kra_pin': kraText.toUpperCase(),
          'kra_certificate_url': kraUrl,
          'tcc_url': tccUrl,
          'is_verified': true,
        }).eq('id', user.id);
      }

      // Insert Bid
      await supabase.from('bids').insert({
        'tender_id': widget.tenderId,
        'farmer_id': user.id,
        'bid_amount': bidAmount,
      });

      if (mounted) _showSuccessDialog(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle,
                      color: Color(0xFF2E7D32), size: 60),
                ),
                const SizedBox(height: 24),
                const Text('Bid Submitted!',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Your offer and compliance documents have been securely sent to ${widget.institutionName}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('BACK TO HOME',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text('Place Your Bid',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tender Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tender Details',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text(widget.institutionName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.shopping_basket_outlined,
                                size: 18, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 8),
                            Text('${widget.quantity} of ${widget.itemName}',
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🔥 NEW: DOUBLE DOCUMENT UPLOAD SECTION 🔥
                  if (!_isVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.orange.shade300, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.gavel, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text('PPADA Legal Requirements',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.orange.shade900)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'To supply a government institution, you must complete Tier 1 Verification. You only do this once.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.orange.shade900),
                          ),
                          const SizedBox(height: 20),

                          // National ID
                          TextField(
                            controller: _idController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'National ID Number',
                              prefixIcon:
                                  const Icon(Icons.badge, color: Colors.grey),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // KRA PIN TEXT
                          TextField(
                            controller: _kraController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'KRA PIN (e.g., A123456789Z)',
                              prefixIcon: const Icon(Icons.account_balance,
                                  color: Colors.grey),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // KRA CERTIFICATE UPLOAD
                          const Text('KRA PIN Certificate',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickImage(true), // true = KRA
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _kraImage == null
                                        ? Colors.grey.shade300
                                        : const Color(0xFF2E7D32),
                                    style: BorderStyle.solid),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      _kraImage == null
                                          ? Icons.upload_file
                                          : Icons.check_circle,
                                      color: _kraImage == null
                                          ? Colors.grey
                                          : const Color(0xFF2E7D32)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _kraImage == null
                                        ? 'Upload KRA Certificate'
                                        : 'KRA Certificate Attached',
                                    style: TextStyle(
                                        color: _kraImage == null
                                            ? Colors.grey
                                            : const Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // TCC UPLOAD
                          const Text('Tax Compliance Certificate (TCC)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickImage(false), // false = TCC
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _tccImage == null
                                        ? Colors.grey.shade300
                                        : const Color(0xFF2E7D32),
                                    style: BorderStyle.solid),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      _tccImage == null
                                          ? Icons.upload_file
                                          : Icons.check_circle,
                                      color: _tccImage == null
                                          ? Colors.grey
                                          : const Color(0xFF2E7D32)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _tccImage == null
                                        ? 'Upload TCC Document'
                                        : 'TCC Document Attached',
                                    style: TextStyle(
                                        color: _tccImage == null
                                            ? Colors.grey
                                            : const Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Bidding Input Section
                  const Text('Your Offer',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _bidController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: 'KES ',
                      prefixStyle: const TextStyle(
                          fontSize: 24,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'Enter the total amount you are charging for this delivery.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 40),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitBid,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('CONFIRM BID',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
