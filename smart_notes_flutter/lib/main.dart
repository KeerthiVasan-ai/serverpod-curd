import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_notes_client/smart_notes_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

// ─────────────────────────────────────────────
// Global Serverpod client
// ─────────────────────────────────────────────
late final Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final serverUrl = await getServerUrl();
  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor();
  runApp(const SmartNotesApp());
}

// ─────────────────────────────────────────────
// App Root
// ─────────────────────────────────────────────
class SmartNotesApp extends StatelessWidget {
  const SmartNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Notes',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFF6C63FF);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        surface: const Color(0xFF0D0D14),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0D14),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardColor: const Color(0xFF16161F),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1C28),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2A3C), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
class AppColors {
  static const background = Color(0xFF0D0D14);
  static const surface = Color(0xFF16161F);
  static const surfaceAlt = Color(0xFF1C1C28);
  static const border = Color(0xFF2A2A3C);
  static const violet = Color(0xFF6C63FF);
  static const violetLight = Color(0xFF9B94FF);
  static const pink = Color(0xFFFF6B9D);
  static const cyan = Color(0xFF00D4FF);
  static const green = Color(0xFF00E5A0);
  static const textPrimary = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFF8888AA);
  static const textMuted = Color(0xFF55556A);
}

// ─────────────────────────────────────────────
// Home Screen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Note> _notes = [];
  List<NoteSearchResult> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isSearchMode = false;
  String _error = '';

  final _searchController = TextEditingController();
  Timer? _debounce;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadNotes();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Data Methods ──────────────────────────

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final notes = await client.notes.getAllNotes();
      setState(() => _notes = notes);
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _isSearchMode = false;
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearchMode = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _isSearching = true;
      _error = '';
    });
    try {
      final results = await client.notes.searchNotes(query);
      setState(() => _searchResults = results);
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _deleteNote(int id) async {
    try {
      await client.notes.deleteNote(id);
      await _loadNotes();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  // ── UI ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildStatusBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.violet, AppColors.pink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Smart Notes',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Full-Stack Dart · Serverpod · Gemini AI',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          _buildStatsChips(),
        ],
      ),
    );
  }

  Widget _buildStatsChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StatChip(
          icon: Icons.note_alt_rounded,
          label: '${_notes.length}',
          sublabel: 'notes',
          color: AppColors.violet,
        ),
        const SizedBox(height: 6),
        _StatChip(
          icon: Icons.psychology_rounded,
          label: 'AI',
          sublabel: 'active',
          color: AppColors.green,
          pulse: true,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search semantically… e.g. "things to buy"',
          hintStyle: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.violet,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearchMode = false;
                      _searchResults = [];
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error,
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isSearchMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.violet.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 12, color: AppColors.violetLight),
                  const SizedBox(width: 4),
                  Text(
                    _isSearching
                        ? 'Searching with AI…'
                        : '${_searchResults.length} semantic match${_searchResults.length != 1 ? 'es' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.violetLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 12);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.violet),
      );
    }

    final items = _isSearchMode ? _searchResults : null;
    final notes = _isSearchMode ? null : _notes;

    if (_isSearchMode && _searchResults.isEmpty && !_isSearching) {
      return _buildEmptyState(
        icon: Icons.manage_search_rounded,
        title: 'No semantic matches',
        subtitle: 'Try a different concept or check your Gemini API key.',
        color: AppColors.cyan,
      );
    }

    if (!_isSearchMode && _notes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.note_add_rounded,
        title: 'No notes yet',
        subtitle: 'Tap the + button to create your first note.',
        color: AppColors.violet,
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        color: AppColors.violet,
        backgroundColor: AppColors.surface,
        onRefresh: _loadNotes,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          itemCount: _isSearchMode ? items!.length : notes!.length,
          itemBuilder: (context, index) {
            if (_isSearchMode) {
              final result = items![index];
              return _NoteCard(
                note: result.note,
                score: result.score,
                rank: index + 1,
                onDelete: () => _deleteNote(result.note.id!),
              );
            } else {
              return _NoteCard(
                note: notes![index],
                onDelete: () => _deleteNote(notes[index].id!),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showAddNoteSheet(context),
      backgroundColor: AppColors.violet,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Add Note',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    );
  }

  // ── Add Note Sheet ───────────────────────

  void _showAddNoteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddNoteSheet(
        onSave: (title, content) async {
          Navigator.of(context).pop();
          setState(() => _isLoading = true);
          try {
            await client.notes.addNote(title, content);
            await _loadNotes();
          } catch (e) {
            setState(() {
              _isLoading = false;
              _error = e.toString();
            });
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Note Card
// ─────────────────────────────────────────────
class _NoteCard extends StatefulWidget {
  final Note note;
  final double? score;
  final int? rank;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    this.score,
    this.rank,
    required this.onDelete,
  });

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevationAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    if (widget.score == null) return AppColors.violet;
    if (widget.score! > 0.85) return AppColors.green;
    if (widget.score! > 0.70) return AppColors.cyan;
    return AppColors.violetLight;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _elevationAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -2 * _elevationAnim.value),
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _hovered = true);
          _hoverController.forward();
        },
        onExit: (_) {
          setState(() => _hovered = false);
          _hoverController.reverse();
        },
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? _accentColor.withValues(alpha: 0.4)
                    : AppColors.border,
                width: 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: _accentColor.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rank / score badge
                      if (widget.score != null) ...[
                        _ScoreBadge(
                          score: widget.score!,
                          rank: widget.rank!,
                          color: _accentColor,
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Title
                      Expanded(
                        child: Text(
                          widget.note.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),

                      // Delete button
                      GestureDetector(
                        onTap: () => _confirmDelete(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Content
                  Text(
                    widget.note.content,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 14),

                  // Footer
                  Row(
                    children: [
                      // Has embedding indicator
                      if (widget.note.embedding != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppColors.violet.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.hub_rounded,
                                  size: 10, color: AppColors.violetLight),
                              const SizedBox(width: 4),
                              Text(
                                'Embedded',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.violetLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      const Spacer(),

                      // Timestamp
                      Text(
                        _formatDate(widget.note.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _confirmDelete(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Delete Note?',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently delete "${widget.note.title}".',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            child: Text('Delete',
                style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Score Badge
// ─────────────────────────────────────────────
class _ScoreBadge extends StatelessWidget {
  final double score;
  final int rank;
  final Color color;

  const _ScoreBadge({
    required this.score,
    required this.rank,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '#$rank',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$pct%',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stat Chip
// ─────────────────────────────────────────────
class _StatChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool pulse;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    this.pulse = false,
  });

  @override
  State<_StatChip> createState() => _StatChipState();
}

class _StatChipState extends State<_StatChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.pulse) _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity = widget.pulse
            ? 0.6 + (_pulseController.value * 0.4)
            : 1.0;
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: widget.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 13, color: widget.color),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                ),
                Text(
                  widget.sublabel,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: widget.color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Note Bottom Sheet
// ─────────────────────────────────────────────
class _AddNoteSheet extends StatefulWidget {
  final Future<void> Function(String title, String content) onSave;

  const _AddNoteSheet({required this.onSave});

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSave(title, content);
    } catch (e) {
      // Error is handled in parent
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.violet, AppColors.pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Note',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Will be embedded with Gemini AI',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Title field
          TextField(
            controller: _titleController,
            autofocus: true,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'Note title…',
              prefixIcon: Icon(Icons.title_rounded,
                  color: AppColors.textMuted, size: 18),
            ),
          ),

          const SizedBox(height: 12),

          // Content field
          TextField(
            controller: _contentController,
            maxLines: 5,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
            ),
            decoration: const InputDecoration(
              hintText: 'Write your note here…',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.notes_rounded,
                    color: AppColors.textMuted, size: 18),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // AI notice
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.violet.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 14, color: AppColors.violetLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gemini will generate an embedding vector for semantic search',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.violetLight,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.violet,
                disabledBackgroundColor:
                    AppColors.violet.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Generating embedding…',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Save Note',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
