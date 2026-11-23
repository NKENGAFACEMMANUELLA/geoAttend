import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geoattend/core/core.dart';

import '../widgets/states.dart';

/// Loading / loaded / offline / error wrapper. Deliberately not Equatable so
/// every emit rebuilds the UI, even if the repository returns the same list.
class Async<T> {
  const Async({this.status = ViewStatus.loading, this.data, this.error});
  final ViewStatus status;
  final T? data;
  final String? error;
}

abstract class AsyncCubit<T> extends Cubit<Async<T>> {
  AsyncCubit() : super(const Async());

  /// Runs [task], emitting loading -> loaded/offline/error.
  Future<void> run(Future<T> Function() task) async {
    emit(Async(status: ViewStatus.loading, data: state.data));
    try {
      emit(Async(status: ViewStatus.loaded, data: await task()));
    } on NoConnectionException {
      emit(Async(status: ViewStatus.offline, data: state.data));
    } on AppException catch (e) {
      emit(Async(status: ViewStatus.error, data: state.data, error: e.message));
    } catch (_) {
      emit(Async(
          status: ViewStatus.error,
          data: state.data,
          error: 'Something went wrong. Please try again.'));
    }
  }

  /// Silently replaces the data (no loading flicker).
  void set(T data) => emit(Async(status: ViewStatus.loaded, data: data));
}

/// Builds [builder] when data is available, otherwise a skeleton, the
/// "No Internet Connection" screen or the "Something went wrong" screen.
class AsyncBuilder<C extends AsyncCubit<T>, T> extends StatelessWidget {
  const AsyncBuilder({super.key, required this.builder, this.onRetry});

  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, Async<T>>(builder: (context, s) {
      switch (s.status) {
        case ViewStatus.offline:
          return NoInternetView(onRetry: onRetry);
        case ViewStatus.error:
          return ErrorStateView(message: s.error, onRetry: onRetry);
        case ViewStatus.loading:
        case ViewStatus.loaded:
          if (s.data != null) return builder(context, s.data as T);
          return const SkeletonList();
      }
    });
  }
}
