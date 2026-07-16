/// Generic contract for anything that stores and retrieves items of
/// type [T]. Implemented by [JsonTaskRepository] for [Task] persistence,
/// but written generically (`Repository<T>`) so it isn't tied to tasks.
abstract class Repository<T> {
  Future<List<T>> getAll();
  Future<void> add(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
}
