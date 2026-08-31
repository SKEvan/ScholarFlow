// In-memory cache for per-project draft section content (Abstract,
// Introduction, Literature Review, Methodology). There is no backend
// endpoint for these sections yet, so content only survives for the
// lifetime of the app process — it resets on restart.
class ProjectSectionStore {
  static final ProjectSectionStore _instance = ProjectSectionStore._internal();
  factory ProjectSectionStore() => _instance;
  ProjectSectionStore._internal();

  final Map<String, String> _content = {};

  String _key(String projectId, String sectionKey) => '$projectId::$sectionKey';

  String getContent(String projectId, String sectionKey) =>
      _content[_key(projectId, sectionKey)] ?? '';

  void setContent(String projectId, String sectionKey, String content) {
    _content[_key(projectId, sectionKey)] = content;
  }
}
