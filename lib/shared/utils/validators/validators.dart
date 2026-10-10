class Validators {
  Validators._();

  static String? required(String? v, [String field = 'Este campo']) {
    if (v == null || v.trim().isEmpty) return '$field es obligatorio';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'El correo es obligatorio';
    final regex = RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!regex.hasMatch(v.trim())) return 'Correo inválido';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}