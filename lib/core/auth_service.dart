import 'supabase_client.dart';

class AuthService {
  static String usuarioToEmail(String usuario) {
    return '${usuario.toLowerCase()}@app.local';
  }

  static Future<Map<String, dynamic>?> login({
    required String usuario,
    required String password,
  }) async {
    final email = usuarioToEmail(usuario);

    final authResponse = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = authResponse.user;
    if (user == null) return null;

    final data =
        await supabase.from('usuarios').select().eq('id', user.id).single();

    return {
      'id': user.id,
      'nombre': data['nombre'],
      'rol': data['rol'],
      'rutas': List<int>.from(data['rutas']),
    };
  }

  static Future<void> logout() async {
    await supabase.auth.signOut();
  }
}
