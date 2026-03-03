import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyLpoScreen extends StatefulWidget {
  final String tenderId;

  const VerifyLpoScreen({Key? key, required this.tenderId}) : super(key: key);

  @override
  State<VerifyLpoScreen> createState() => _VerifyLpoScreenState();
}

class _VerifyLpoScreenState extends State<VerifyLpoScreen> {
  bool _isLoading = true;
  bool _isValid = false;
  Map<String, dynamic>? _tenderData;
  Map<String, dynamic>? _winningFarmer;
  String _agreedPrice = '';

  @override
  void initState() {
    super.initState();
    _verifyLpo();
  }

  Future<void> _verifyLpo() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Securely fetch the exact tender. We use .maybeSingle() because a forged ID will return null.
      final response = await supabase
          .from('tenders')
          .select('*, bids(*, profiles(*))')
          .eq('id', widget.tenderId)
          .eq('status', 'closed') // MUST be closed to be a valid LPO
          .maybeSingle();

      if (response != null) {
        // 2. Find the winning farmer from the bids
        final bids = response['bids'] as List<dynamic>? ?? [];
        for (var bid in bids) {
          if (bid['status'] == 'won' || bid['status'] == 'accepted') {
            _winningFarmer = bid['profiles'];
            _agreedPrice = bid['bid_amount'].toString();
            break;
          }
        }

        if (_winningFarmer != null) {
          _isValid = true;
          _tenderData = response;
        }
      }
    } catch (e) {
      debugPrint('Verification Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('Soko Tender | Official Verification', style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: _isLoading 
            ? const CircularProgressIndicator(color: Color(0xFF2E7D32))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500), // Keeps it looking good on web and mobile
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                    ),
                    child: _isValid ? _buildValidState() : _buildInvalidState(),
                  ),
                ),
              ),
      ),
    );
  }

  // --- THE GREEN "VALID" SCREEN ---
  Widget _buildValidState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.verified_rounded, color: Colors.green, size: 80),
        const SizedBox(height: 16),
        const Text('VERIFIED LPO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 2)),
        const SizedBox(height: 8),
        const Text('This document is authentic and officially authorized by the institution.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const Divider(height: 40, thickness: 1),
        
        _buildDetailRow('Institution:', _tenderData!['institution_name']),
        _buildDetailRow('LPO Number:', widget.tenderId.substring(0, 8).toUpperCase()),
        _buildDetailRow('Authorized Supplier:', _winningFarmer!['full_name'] ?? 'Unknown'),
        _buildDetailRow('Produce:', _tenderData!['crop_name']),
        _buildDetailRow('Quantity Expected:', '${_tenderData!['quantity']} ${_tenderData!['unit'] ?? ''}'),
        _buildDetailRow('Agreed Price:', 'KES $_agreedPrice'),
        
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Secured by Soko Tender', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  // --- THE RED "FORGED" SCREEN ---
  Widget _buildInvalidState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cancel_rounded, color: Colors.red, size: 80),
        const SizedBox(height: 16),
        const Text('INVALID DOCUMENT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 1)),
        const SizedBox(height: 16),
        const Text(
          'WARNING: This LPO number does not exist in our database, or the tender has not been officially closed. Do not accept goods under this LPO.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 30),
        const Text('LPO ID Scanned:', style: TextStyle(color: Colors.grey, fontSize: 12)),
        Text(widget.tenderId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
    );
  }
}