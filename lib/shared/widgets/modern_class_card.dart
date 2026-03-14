import 'package:flutter/material.dart';
import 'package:ibex_app/core/models/class_model.dart';

class ModernClassCard extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback onTap;

  const ModernClassCard({
    super.key,
    required this.classModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a placeholder image URL based on class subject/name
    final String imageUrl = _getImageUrlForSubject(classModel.subjectName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF192233), // Surface Dark
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Badge
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF135bec), // Primary
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ONGOING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Expanded(
              child: Text(
                classModel.subjectName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Subtitle
            Row(
              children: [
                const Icon(
                  Icons.room,
                  color: Color(0xFF8E99A4), // Slate 400
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${classModel.subjectName} • Prof. Teacher', // Mocking room/prof to fit design
                    style: const TextStyle(
                      color: Color(0xFF8E99A4),
                      fontSize: 12,
                      fontFamily: 'Lexend',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getImageUrlForSubject(String name) {
    if (name.toLowerCase().contains('math') || name.toLowerCase().contains('calculus')) {
      return 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=500&q=80';
    } else if (name.toLowerCase().contains('chem') || name.toLowerCase().contains('science')) {
      return 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=500&q=80';
    } else {
      return 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=500&q=80';
    }
  }
}
