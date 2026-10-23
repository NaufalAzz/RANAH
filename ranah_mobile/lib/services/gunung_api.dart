abstract interface class GunungApi {
  Future<List<dynamic>> getGunung();
  Future<Map<String, dynamic>> getDetailGunung(int id);
}
