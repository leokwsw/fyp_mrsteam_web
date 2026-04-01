import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;

  const AppBarWidget({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          GestureDetector(
            onTap: () => context.go('/dashboard'),
            child: Row(
              children: [
                Icon(Icons.school, size: 28),
                const SizedBox(width: 12),
                Text(
                  'TutorTrack',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Links
          Row(
            children: [
              _NavLink(
                text: 'Dashboard',
                isActive: currentRoute == '/dashboard',
                onTap: () => context.go('/dashboard'),
              ),
              const SizedBox(width: 40),
              _NavLink(
                text: 'Class',
                isActive: currentRoute.contains('/class'),
                onTap: () => context.go('/class'),
              ),
              const SizedBox(width: 40),
              _NavLink(
                text: 'School',
                isActive: currentRoute.contains('/school'),
                onTap: () => context.go('/school'),
              ),
              const SizedBox(width: 40),
              _NavLink(
                text: 'Attendance',
                isActive: currentRoute == '/attendance',
                onTap: () => context.go('/attendance'),
              ),
              const SizedBox(width: 40),
              _NavLink(
                text: 'Leave Requests',
                isActive: currentRoute.contains('/leave'),
                onTap: () => context.go('/leave'),
              ),
              const SizedBox(width: 40),
              _NavLink(
                text: 'Account',
                isActive: currentRoute.contains('/account'),
                onTap: () => context.go('/account'),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => context.go('/myprofile'),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _NavLink extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLink({
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}