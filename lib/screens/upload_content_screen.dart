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
  final _tagsController = TextEditingController();
  String _category = 'Reviews';
  String _visibility = 'Public';
  String _publishOption = 'Now';
  bool _allowComments = true;
  bool _allowGifting = true;
  bool _monetize = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _selectedThumbnail;
  String? _videoSource;
  DateTime? _scheduledDate;

  final _categories = ['Reviews', 'Analysis', 'Lists', 'News', 'Fun', 'Trailers', 'Tutorials', 'Interviews', 'Vlogs', 'Behind the Scenes'];
  final _visibilities = ['Public', 'Unlisted', 'Private'];
  final _publishOptions = ['Now', 'Schedule', 'Draft'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Upload Content', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          InteractiveCard(
            onTap: _saveDraft,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Save Draft', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoSourcePicker(),
            const SizedBox(height: 20),
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
            const SizedBox(height: 16),
            const Text('Tags (comma separated)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. movie, review, 4k',
                hintStyle: TextStyle(color: Colors.white.withAlpha(50)),
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            _buildDropdown('Category', _category, _categories, (v) => setState(() => _category = v)),
            const SizedBox(height: 16),
            _buildDropdown('Visibility', _visibility, _visibilities, (v) => setState(() => _visibility = v)),
            const SizedBox(height: 16),
            _buildPublishOptions(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _toggleRow(Icons.chat_bubble_outline, 'Allow Comments', _allowComments, (v) => setState(() => _allowComments = v)),
                  const Divider(color: Color(0xFF2A2A2A), height: 20),
                  _toggleRow(Icons.card_giftcard_outlined, 'Allow Gifting', _allowGifting, (v) => setState(() => _allowGifting = v)),
                  const Divider(color: Color(0xFF2A2A2A), height: 20),
                  _toggleRow(Icons.monetization_on_outlined, 'Monetize', _monetize, (v) => setState(() => _monetize = v)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isUploading) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE50914))),
                        const SizedBox(width: 12),
                        const Text('Processing video...', style: TextStyle(color: Colors.white, fontSize: 15)),
                        const Spacer(),
                        Text('${(_uploadProgress * 100).toInt()}%', style: const TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.white10,
                        color: const Color(0xFFE50914),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _uploadProgress < 0.3 ? 'Uploading...' : (_uploadProgress < 0.7 ? 'Processing...' : 'Publishing...'),
                      style: const TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _upload,
                icon: Icon(_isUploading ? Icons.hourglass_top : Icons.cloud_upload),
                label: Text(
                  _isUploading
                      ? 'Uploading...'
                      : _publishOption == 'Draft' ? 'Save as Draft' : _publishOption == 'Schedule' ? 'Schedule Publish' : 'Publish Now',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
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

  Widget _buildVideoSourcePicker() {
    return InteractiveCard(
      onTap: () => _showSourcePicker(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _videoSource != null ? const Color(0xFFE50914).withAlpha(80) : Colors.white10, width: 1.5),
        ),
        child: _videoSource != null
            ? Column(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 32),
                  const SizedBox(height: 8),
                  Text(_videoSource!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('Tap to change source', style: TextStyle(color: Colors.white.withAlpha(60), fontSize: 12)),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.video_library_outlined, color: Color(0xFFE50914), size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('Select Video File', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('MP4, MOV, AVI \u2022 Max 4GB', style: TextStyle(color: Colors.white.withAlpha(50), fontSize: 13)),
                ],
              ),
      ),
    );
  }

  void _showSourcePicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Select Video Source', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _sourceOption(Icons.videocam, 'Record Now', 'Capture video using your camera'),
            const SizedBox(height: 8),
            _sourceOption(Icons.folder, 'Browse Files', 'Select from device storage'),
            const SizedBox(height: 8),
            _sourceOption(Icons.link, 'Paste URL', 'Import from a video link'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption(IconData icon, String title, String subtitle) {
    return InteractiveCard(
      onTap: () {
        setState(() => _videoSource = title);
        Navigator.pop(context);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE50914), size: 24),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPicker() {
    return InteractiveCard(
      onTap: () {
        HapticFeedback.lightImpact();
        _showThumbnailPicker();
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
                    const Text('Add Thumbnail', style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text('16:9 recommended', style: TextStyle(color: Colors.white.withAlpha(40), fontSize: 12)),
                  ],
                ),
        ),
      ),
    );
  }

  void _showThumbnailPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Choose Thumbnail', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12, runSpacing: 12,
              children: ['\u{1F3AC}', '\u{1F3A5}', '\u{1F3AD}', '\u{1F3AA}', '\u{1F3AF}', '\u{1F3AE}', '\u{1F3A8}', '\u{1F680}', '\u{1F4A5}', '\u{1F525}', '\u{1F31F}', '\u{1F389}', '\u{1F38A}', '\u{1F383}', '\u{1F47B}', '\u{1F916}', '\u{1F9B8}', '\u{1F9B9}', '\u{1F9DB}', '\u{1F9D9}']
                  .map((e) => GestureDetector(
                    onTap: () {
                      setState(() => _selectedThumbnail = e);
                      Navigator.pop(ctx);
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: _selectedThumbnail == e ? const Color(0xFFE50914).withAlpha(30) : Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _selectedThumbnail == e ? const Color(0xFFE50914) : Colors.transparent),
                      ),
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
                    ),
                  ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Publish', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            children: _publishOptions.map((opt) {
              final active = _publishOption == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _publishOption = opt);
                      if (opt == 'Schedule') _showSchedulePicker();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFE50914) : Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(opt, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_publishOption == 'Schedule' && _scheduledDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFFE50914), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Scheduled for ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}',
                  style: const TextStyle(color: Color(0xFFE50914), fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showSchedulePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE50914),
            onPrimary: Colors.white,
            surface: Color(0xFF1F1F1F),
          ),
        ),
        child: child!,
      ),
    ).then((date) {
      if (date != null) {
        setState(() => _scheduledDate = date);
      } else if (_publishOption == 'Schedule') {
        setState(() => _publishOption = 'Now');
      }
    });
  }

  void _saveDraft() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved!'), backgroundColor: Color(0xFF43A047), behavior: SnackBarBehavior.floating),
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
        SnackBar(
          content: Text(
            _publishOption == 'Draft' ? 'Draft saved!' : _publishOption == 'Schedule' ? 'Video scheduled!' : 'Video published successfully!',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
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
}
