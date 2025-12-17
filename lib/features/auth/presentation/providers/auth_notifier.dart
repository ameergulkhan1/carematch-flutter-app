import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_credentials.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../../../core/errors/failures.dart';
import '../../../../injection_container.dart';

/// Auth State Management with Riverpod
///
/// **USAGE EXAMPLE IN SCREENS:**
///
/// ```dart
/// // 1. Import the provider
/// import 'package:flutter_riverpod/flutter_riverpod.dart';
/// import 'package:carematch_app/features/auth/presentation/providers/auth_notifier.dart';
///
/// // 2. Make your screen a ConsumerWidget or ConsumerStatefulWidget
/// class MyLoginScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     // 3. Watch the auth state
///     final authState = ref.watch(authProvider);
///
///     // 4. Access state properties
///     if (authState.isLoading) {
///       return CircularProgressIndicator();
///     }
///
///     if (authState.error != null) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(authState.error.toString())),
///       );
///     }
///
///     return ElevatedButton(
///       onPressed: () {
///         // 5. Call methods from the notifier
///         ref.read(authProvider.notifier).signIn(
///           email: 'user@example.com',
///           password: 'password123',
///         );
///       },
///       child: Text('Sign In'),
///     );
///   }
/// }
/// ```

/// Auth state
class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final bool isAuthenticated;
  final Failure? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    bool? isAuthenticated,
    Failure? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

/// Auth provider using Riverpod
class AuthNotifier extends StateNotifier<AuthState> {
  final SignIn _signIn;
  final SignOut _signOut;
  final RegisterClient _registerClient;
  final RegisterCaregiver _registerCaregiver;
  final GetCurrentUser _getCurrentUser;
  final SendPasswordResetEmail _sendPasswordResetEmail;
  final UpdateProfile _updateProfile;
  final DeleteAccount _deleteAccount;

  AuthNotifier({
    required SignIn signIn,
    required SignOut signOut,
    required RegisterClient registerClient,
    required RegisterCaregiver registerCaregiver,
    required GetCurrentUser getCurrentUser,
    required SendPasswordResetEmail sendPasswordResetEmail,
    required UpdateProfile updateProfile,
    required DeleteAccount deleteAccount,
  })  : _signIn = signIn,
        _signOut = signOut,
        _registerClient = registerClient,
        _registerCaregiver = registerCaregiver,
        _getCurrentUser = getCurrentUser,
        _sendPasswordResetEmail = sendPasswordResetEmail,
        _updateProfile = updateProfile,
        _deleteAccount = deleteAccount,
        super(const AuthState());

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final credentials = SignInCredentials(email: email, password: password);
    final result = await _signIn(credentials);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure,
        isAuthenticated: false,
      ),
      (user) => state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      ),
    );
  }

  /// Register client
  Future<void> registerClient(ClientSignUpCredentials credentials) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _registerClient(credentials);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure,
      ),
      (user) => state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      ),
    );
  }

  /// Register caregiver
  Future<void> registerCaregiver(CaregiverSignUpCredentials credentials) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _registerCaregiver(credentials);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure,
      ),
      (user) => state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      ),
    );
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    final result = await _signOut();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure,
      ),
      (_) => state = const AuthState(
        isLoading: false,
        isAuthenticated: false,
      ),
    );
  }

  /// Get current user
  Future<void> getCurrentUser() async {
    state = state.copyWith(isLoading: true);

    final result = await _getCurrentUser();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure,
        isAuthenticated: false,
      ),
      (user) => state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      ),
    );
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    final credentials = PasswordResetCredentials(email: email);
    final result = await _sendPasswordResetEmail(credentials);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  /// Update profile
  Future<bool> updateProfile(String uid, Map<String, dynamic> updates) async {
    state = state.copyWith(isLoading: true, error: null);

    final params = UpdateProfileParams(uid: uid, updates: updates);
    final result = await _updateProfile(params);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
    );
  }

  /// Delete account
  Future<bool> deleteAccount(String uid) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteAccount(uid);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
        return false;
      },
      (_) {
        state = const AuthState(isLoading: false, isAuthenticated: false);
        return true;
      },
    );
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    signIn: sl<SignIn>(),
    signOut: sl<SignOut>(),
    registerClient: sl<RegisterClient>(),
    registerCaregiver: sl<RegisterCaregiver>(),
    getCurrentUser: sl<GetCurrentUser>(),
    sendPasswordResetEmail: sl<SendPasswordResetEmail>(),
    updateProfile: sl<UpdateProfile>(),
    deleteAccount: sl<DeleteAccount>(),
  );
});
