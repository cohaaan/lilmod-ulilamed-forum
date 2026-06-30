import 'auth_repository.dart';
import 'chavrusa_repository.dart';
import 'forum_repository.dart';
import 'seforim_repository.dart';

/// Lazily-initialised singletons. They read `Supabase.instance` on first use,
/// which is always after `Supabase.initialize()` has run in main().
final authRepository = AuthRepository();
final chavrusaRepository = ChavrusaRepository();
final forumRepository = ForumRepository();

/// Read-only Sefaria API access for the Seforim browser.
final seforimRepository = SeforimRepository();
