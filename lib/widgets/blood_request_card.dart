import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class BloodRequestCard extends StatelessWidget {
  final BloodRequest request;

  const BloodRequestCard({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getUrgencyColor().withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showDetailDialog(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBloodTypeTag(),
                  const SizedBox(width: 8),
                  _buildUrgencyTag(),
                  const Spacer(),
                  Text(
                    timeago.format(request.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Patient: ${request.patientName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hospital: ${request.hospital}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              if (request.notes != null && request.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  request.notes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _makeCall(context),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _respondToDonation(context),
                    child: const Text('Respond'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBloodTypeTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        request.bloodType,
        style: TextStyle(
          color: Colors.red.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildUrgencyTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getUrgencyColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        _getUrgencyText(),
        style: TextStyle(
          color: _getUrgencyColor(),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getUrgencyColor() {
    switch (request.urgency) {
      case 'critical':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getUrgencyText() {
    switch (request.urgency) {
      case 'critical':
        return 'Critical';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Standard';
    }
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Blood Request: ${request.bloodType}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Patient', request.patientName),
            _buildDetailItem('Hospital', request.hospital),
            _buildDetailItem('Urgency', _getUrgencyText()),
            if (request.contactPhone != null)
              _buildDetailItem('Contact', request.contactPhone!),
            if (request.unitsNeeded != null)
              _buildDetailItem('Units Needed', '${request.unitsNeeded}'),
            if (request.notes != null && request.notes!.isNotEmpty)
              _buildDetailItem('Notes', request.notes!),
            _buildDetailItem('Requested', timeago.format(request.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _respondToDonation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Respond'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _makeCall(BuildContext context) {
    if (request.contactPhone != null) {
      // Implement call functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling ${request.contactPhone}...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact number available')),
      );
    }
  }

  void _respondToDonation(BuildContext context) {
    // Implement response logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your response!')),
    );
  }
}
