import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/core.dart';
import 'core/router/app_router.dart';
import 'features/admin/domain/admin.dart';
import 'features/admin/presentation/cubit/admin_cubits.dart';
import 'features/attendance/domain/attendance.dart';
import 'features/attendance/presentation/cubit/attendance_cubit.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/correction/domain/correction.dart';
import 'features/correction/presentation/cubit/correction_cubit.dart';
import 'features/leave/domain/leave.dart';
import 'features/leave/presentation/cubit/leave_cubit.dart';
import 'features/notifications/domain/notification.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/workplace/domain/workplace.dart';
import 'features/workplace/presentation/cubit/workplaces_cubit.dart';

class GeoAttendApp extends StatefulWidget {
  const GeoAttendApp({super.key});

  @override
  State<GeoAttendApp> createState() => _GeoAttendAppState();
}

class _GeoAttendAppState extends State<GeoAttendApp> {
  late final GoRouter _router = buildRouter(sl<SessionController>());

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(sl<AuthRepository>(), sl<SessionController>())),
        BlocProvider(create: (_) => AttendanceCubit(sl<AttendanceRepository>())),
        BlocProvider(create: (_) => LeaveCubit(sl<LeaveRepository>())),
        BlocProvider(create: (_) => CorrectionCubit(sl<CorrectionRepository>())),
        BlocProvider(create: (_) => CorrectionApprovalsCubit(sl<CorrectionRepository>())),
        BlocProvider(create: (_) => NotificationsCubit(sl<NotificationsRepository>())),
        BlocProvider(create: (_) => EmployeesCubit(sl<AdminRepository>())),
        BlocProvider(create: (_) => DepartmentsCubit(sl<AdminRepository>())),
        BlocProvider(create: (_) => WorkplacesCubit(sl<WorkplaceRepository>())),
      ],
      child: MaterialApp.router(
        title: 'GeoAttend',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
