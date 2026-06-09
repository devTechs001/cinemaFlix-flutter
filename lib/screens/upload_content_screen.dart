import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cinemaflix/services/creator_service.dart';
import 'package:cinemaflix/widgets/interactive_card.dart';

class UploadContentScreen extends StatefulWidget {
  const UploadContentScreen({super.key});

  @override
  State<UploadContentScreen> createState() => _UploadContentScreenState();
}

class _UploadContentScreenState extends State<UploadContentScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Reviews';
  String _visibility = 'Public';
  bool _allowComments = true;
  bool _allowGifting = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _selectedThumbnail;

  final _categories = ['Reviews', 'Analysis', 'Lists', 'News', 'Fun', 'Trailers', 'Tutorials', 'Interviews'];
  final _visibilities = ['Public', 'Unlisted', 'Private'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Upload Content', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnailPicker(),
            const SizedBox(height: 20),
            const Text('Title', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter video title',
                hintStyle: TextStyle(color: Colors.white.withAlpha(50)),
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your video...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(50)),
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLength: 5000,
            ),
            const SizedBox(height: 20),
            _buildDropdown('Category', _category, _categories, (v) => setState(() => _category = v)),
            const SizedBox(height: 16),
            _buildDropdown('Visibility', _visibility, _visibilities, (v) => setState(() => _visibility = v)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _toggleRow(Icons.chat_bubble_outline, 'Allow Comments', _allowComments, (v) => setState(() => _allowComments = v)),
                  const Divider(color: Color(0xFF2A2A2A), height: 20),
                  _toggleRow(Icons.card_giftcard_outlined, 'Allow Gifting', _allowGifting, (v) => setState(() => _allowGifting = v)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isUploading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text('Uploading... ${(_uploadProgress * 100).toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _upload,
                icon: Icon(_isUploading ? Icons.hourglass_top : Icons.cloud_upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Video', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPicker() {
    return InteractiveCard(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedThumbnail = '🎬');
      },
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10, width: 1.5),
        ),
        child: Center(
          child: _selectedThumbnail != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_selectedThumbnail!, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 8),
                    Text('Tap to change thumbnail', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 13)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: Colors.white.withAlpha(60), size: 48),
                    const SizedBox(height: 12),
                    Text('Add Thumbnail', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 16)),
                    Text('16:9 recommended', style: TextStyle(color: Colors.white.withAlpha(40), fontSize: 12)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(14)),
          child: DropdownButton<String>(
            value: value,
            dropdownColor: const Color(0xFF1F1F1F),
            underline: const SizedBox(),
            isExpanded: true,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            icon: const Icon(Icons.expand_more, color: Colors.white38),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            onChanged: (v) { if (v != null) { HapticFeedback.selectionClick(); onChanged(v); } },
          ),
        ),
      ],
    );
  }

  Widget _toggleRow(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
        Switch(value: value, onChanged: (v) { HapticFeedback.lightImpact(); onChanged(v); }, activeTrackColor: const Color(0xFFE50914)),
      ],
    );
  }

  Future<void> _upload() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), backgroundColor: Color(0xFFE50914), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _isUploading = true);
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _uploadProgress = i / 10);
    }
    creatorService.uploadVideo(_titleController.text.trim(), _category);
    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video uploaded successfully!'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    }
  }
}
