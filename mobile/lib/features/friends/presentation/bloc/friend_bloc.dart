import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/friend_repository_impl.dart';
import 'friend_event.dart';
import 'friend_state.dart';

/// BLoC quản lý bạn bè: danh sách, lời mời, gợi ý, kết bạn, huỷ kết bạn, tìm kiếm.
class FriendBloc extends Bloc<FriendEvent, FriendState> {
  final FriendRepositoryImpl _repository;

  FriendBloc({required FriendRepositoryImpl repository})
      : _repository = repository,
        super(FriendInitial()) {
    on<LoadFriendsEvent>(_onLoadFriends);
    on<LoadFriendRequestsEvent>(_onLoadRequests);
    on<LoadSuggestionsEvent>(_onLoadSuggestions);
    on<SendFriendRequestEvent>(_onSendRequest);
    on<CancelFriendRequestEvent>(_onCancelRequest);
    on<AcceptFriendRequestEvent>(_onAcceptRequest);
    on<RejectFriendRequestEvent>(_onRejectRequest);
    on<UnfriendEvent>(_onUnfriend);
    on<SearchUsersEvent>(_onSearchUsers);
  }

  Future<void> _onLoadFriends(LoadFriendsEvent event, Emitter<FriendState> emit) async {
    emit(FriendLoading());
    try {
      final result = await _repository.getFriends();
      emit(FriendsLoaded(_extractList(result)));
    } on DioException catch (e) {
      emit(FriendError(_extractError(e)));
    } catch (_) {
      emit(FriendError('Không thể tải danh sách bạn bè.'));
    }
  }

  Future<void> _onLoadRequests(LoadFriendRequestsEvent event, Emitter<FriendState> emit) async {
    emit(FriendLoading());
    try {
      final result = await _repository.getRequests();
      emit(FriendRequestsLoaded(_extractList(result)));
    } on DioException catch (e) {
      emit(FriendError(_extractError(e)));
    } catch (_) {
      emit(FriendError('Không thể tải lời mời kết bạn.'));
    }
  }

  Future<void> _onLoadSuggestions(LoadSuggestionsEvent event, Emitter<FriendState> emit) async {
    emit(FriendLoading());
    try {
      final result = await _repository.getSuggestions();
      emit(FriendSuggestionsLoaded(_extractList(result)));
    } on DioException catch (e) {
      emit(FriendError(_extractError(e)));
    } catch (_) {
      emit(FriendError('Không thể tải gợi ý kết bạn.'));
    }
  }

  Future<void> _onSendRequest(SendFriendRequestEvent event, Emitter<FriendState> emit) async {
    try {
      await _repository.sendRequest(event.userId);
      emit(FriendActionSuccess('Đã gửi lời mời kết bạn!'));
    } on DioException catch (e) {
      emit(FriendError(_extractError(e)));
    } catch (_) {
      emit(FriendError('Gửi lời mời thất bại.'));
    }
  }

  Future<void> _onCancelRequest(CancelFriendRequestEvent event, Emitter<FriendState> emit) async {
    try {
      await _repository.unfriend(event.userId);
      emit(FriendActionSuccess('Đã huỷ lời mời kết bạn.'));
    } on DioException catch (e) {
      emit(FriendError(_extractError(e)));
    } catch (_) {
      emit(FriendError('Huỷ lời mời thất bại.'));
    }
  }

  Future<void> _onAcceptRequest(AcceptFriendRequestEvent event, Emitter<FriendState> emit) async {
    try {
      await _repository.acceptRequest(event.requestId);
      emit(FriendActionSuccess('Đã chấp nhận lời mời kết bạn!'));
      add(LoadFriendRequestsEvent());
    } on DioException catch (e) {
      emit(FriendError(_extractError(e)));
    } catch (_) {
      emit(FriendError('Chấp nhận lời mời thất bại.'));
    }
  }

  Future<void> _onRejectRequest(RejectFriendRequestEvent event, Emitter<FriendState> emit) async {
    try {
      await _repository.rejectRequest(event.requestId);
      emit(FriendActionSuccess('Đã từ chối lời mời.'));
      add(LoadFriendRequestsEvent());
    } on DioException catch (e) {
      emit(FriendError(_extractError(e)));
    } catch (_) {
      emit(FriendError('Từ chối lời mời thất bại.'));
    }
  }

  Future<void> _onUnfriend(UnfriendEvent event, Emitter<FriendState> emit) async {
    try {
      await _repository.unfriend(event.userId);
      emit(FriendActionSuccess('Đã huỷ kết bạn.'));
      add(LoadFriendsEvent());
    } on DioException catch (e) {
      emit(FriendError(_extractError(e)));
    } catch (_) {
      emit(FriendError('Huỷ kết bạn thất bại.'));
    }
  }

  Future<void> _onSearchUsers(SearchUsersEvent event, Emitter<FriendState> emit) async {
    emit(FriendLoading());
    try {
      final result = await _repository.searchUsers(event.query);
      final users = _extractList(result);
      emit(UserSearchResults(users));
    } on DioException catch (e) {
      emit(FriendError(_extractError(e)));
    } catch (_) {
      emit(FriendError('Tìm kiếm thất bại.'));
    }
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is List) return data.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data['message'] as String? ?? 'Lỗi';
    } catch (_) {}
    return e.message ?? 'Đã có lỗi xảy ra';
  }
}
