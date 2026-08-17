import 'package:flutter/material.dart';

import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_text_styles.dart';

class ProfileMediaGridWidget extends StatelessWidget {
  const ProfileMediaGridWidget({
    this.images = const <String>[
      AppImages.searchResult1,
      AppImages.searchResult2,
      AppImages.forYouImg,
      AppImages.searchResult2,
      AppImages.forYouImg,
      AppImages.searchResult1,
    ],
    this.showPlayCounts = true,
    super.key,
  });

  final List<String> images;
  final bool showPlayCounts;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: images.length,
      itemBuilder: (BuildContext context, int index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                images[index],
                fit: BoxFit.cover,
              ),
              if (showPlayCounts)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        index == 0
                            ? '12.4K'
                            : (index == 1 ? '8.9K' : '4.2K'),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
