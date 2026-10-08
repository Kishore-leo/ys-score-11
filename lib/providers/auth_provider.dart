import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isPremium => _user?.isPremium ?? false;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    _user = await _storage.loadUser();
    // Pre-create guest/demo session if first launch so user can explore directly or test auth
    if (_user == null) {
      _user = UserModel(
        id: 'user_default',
        name: 'Young Storms Captain',
        emailOrMobile: 'captain@youngstorms.com',
        isPremium: false,
      );
      await _storage.saveUser(_user!);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login({required String emailOrMobile, required String password}) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600)); // Simulated network
    _user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: emailOrMobile.split('@').first,
      emailOrMobile: emailOrMobile,
      isPremium: false,
    );
    await _storage.saveUser(_user!);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String emailOrMobile,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      emailOrMobile: emailOrMobile,
      isPremium: false,
    );
    await _storage.saveUser(_user!);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> upgradeToPremium() async {
    if (_user == null) return;
    _user = UserModel(
      id: _user!.id,
      name: _user!.name,
      emailOrMobile: _user!.emailOrMobile,
      isPremium: true,
      joinedDate: _user!.joinedDate,
    );
    await _storage.saveUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    await _storage.clearUser();
    notifyListeners();
  }
}
