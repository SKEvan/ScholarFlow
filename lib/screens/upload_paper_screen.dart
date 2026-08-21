import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class UploadPaperScreen extends StatefulWidget {
  const UploadPaperScreen({super.key});

  @override
  State<UploadPaperScreen> createState() => _UploadPaperScreenState();
}

class _UploadPaperScreenState extends State<UploadPaperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorsController = TextEditingController();
  final _dateController = TextEditingController();
  final _tagsController = TextEditingController();
  String _selectedProject = 'General Research';

  String? _selectedFileName;
  double? _selectedFileSize;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _dateController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _selectMockFile() {
    setState(() {
      _selectedFileName = 'attention_is_all_you_need.pdf';
      _selectedFileSize = 2.4; // MB
      if (_titleController.text.isEmpty) {
        _titleController.text = 'Attention Is All You Need';
      }
      if (_authorsController.text.isEmpty) {
        _authorsController.text = 'Ashish Vaswani, Noam Shazeer, Niki Parmar';
      }
      if (_dateController.text.isEmpty) {
        _dateController.text = '2017-06-12';
      }
    });
  }

  void _startUpload() {
    if (_selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      Timer.periodic(const Duration(milliseconds: 150), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _uploadProgress += 0.05 + (0.1 * (1.0 - _uploadProgress));
          if (_uploadProgress >= 1.0) {
            _uploadProgress = 1.0;
            timer.cancel();

            // Delay for completion state
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted) return;
              setState(() {
                _isUploading = false;
              });

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text('Upload Success'),
                    ],
                  ),
                  content: const Text(
                    'Paper uploaded and indexed successfully!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // pop dialog
                        Navigator.of(context).pop(); // pop screen
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            });
          }
        });
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Upload Paper',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Drop Zone Section Header
                          Text(
                            'DOCUMENT SOURCE',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Drop Zone Card
                          GestureDetector(
                            onTap: _selectMockFile,
                            child: CustomPaint(
                              painter: DashedRectPainter(
                                color: theme.colorScheme.secondary,
                                strokeWidth: 1.5,
                              ),
                              child: Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.picture_as_pdf,
                                        size: 28,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedFileName ?? 'Select PDF File',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedFileName != null
                                          ? '${_selectedFileSize}MB • Ready to upload'
                                          : 'Max size: 50MB',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Metadata Section Header
                          Text(
                            'PAPER METADATA',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Paper Title
                          Text(
                            'Paper Title',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Attention Is All You Need',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter paper title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Authors
                          Text(
                            'Authors',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _authorsController,
                            decoration: const InputDecoration(
                              hintText: 'Separate with commas',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter authors';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Row: Date and Project
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Publication Date',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _dateController,
                                      readOnly: true,
                                      onTap: _selectDate,
                                      decoration: const InputDecoration(
                                        hintText: 'YYYY-MM-DD',
                                        suffixIcon: Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Project',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _selectedProject,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'General Research',
                                          child: Text('General Research'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'AI Ethics Thesis',
                                          child: Text('AI Ethics Thesis'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Neural Architectures',
                                          child: Text('Neural Architectures'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedProject = value;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Tags
                          Text(
                            'Tags',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _tagsController,
                            decoration: InputDecoration(
                              hintText: 'Add keywords...',
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildTagChip(theme, 'AI'),
                                    const SizedBox(width: 4),
                                    _buildTagChip(theme, 'NLP'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // AI Insight
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.secondaryContainer
                                    .withOpacity(0.2),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: theme.colorScheme.secondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI PROCESSING ENABLED',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.secondary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Uploading will automatically generate a summary, extract key findings, and map citations to your graph.",
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Fixed Bottom Action
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startUpload,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Upload'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Upload Progress Overlay
          if (_isUploading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                strokeWidth: 6,
                                backgroundColor: theme
                                    .colorScheme
                                    .outlineVariant
                                    .withOpacity(0.5),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Analyzing Manuscript',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Extracting abstract and citations...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagChip(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}

// Custom Painter for dashed borders
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DashedRectPainter({required this.color, this.strokeWidth = 1.5});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );

    const dashWidth = 8.0;
    const dashSpace = 4.0;
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        canvas.drawPath(
          measurePath.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
