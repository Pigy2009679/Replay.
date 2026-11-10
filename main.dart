import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'services/screen_capture.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReplayApp());
}

const navy = Color(0xFF0B1220);
const panel = Color(0xFF151F31);
const blue = Color(0xFF4C8DFF);
const muted = Color(0xFF93A4BC);

class ReplayApp extends StatelessWidget {
  const ReplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REPLAY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.dark,
          surface: panel,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: panel,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF26344A)),
          ),
        ),
      ),
      home: const ReplayShell(),
    );
  }
}

class ReplayShell extends StatefulWidget {
  const ReplayShell({super.key});

  @override
  State<ReplayShell> createState() => _ReplayShellState();
}

class _ReplayShellState extends State<ReplayShell> {
  int tab = 0;
  final capture = ScreenCapture();
  bool recording = false;
  bool paused = false;
  String status = 'Ready to record';
  List<RecordingFile> recordings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final items = await capture.listRecordings();
      if (mounted) setState(() => recordings = items);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> start() async {
    try {
      final result = await capture.startRecording();
      if (!mounted) return;
      if (result) {
        setState(() {
          recording = true;
          paused = false;
          status = 'Recording with system indicator enabled';
        });
      } else {
        setState(() => status = 'Recording was not started');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => status = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> togglePause() async {
    try {
      if (paused) {
        await capture.resumeRecording();
      } else {
        await capture.pauseRecording();
      }
      if (mounted) setState(() {
        paused = !paused;
        status = paused ? 'Recording paused' : 'Recording resumed';
      });
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await capture.stopRecording();
      if (!mounted) return;
      setState(() {
        recording = false;
        paused = false;
        status = 'Recording saved';
      });
      await refresh();
    } catch (e) {
      if (mounted) setState(() => status = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      homePage(),
      libraryPage(),
      historyPage(),
      settingsPage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: blue.withOpacity(.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: blue),
                  ),
                  const SizedBox(width: 11),
                  const Text('REPLAY', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2,
                  )),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => tab = 3),
                    icon: const Icon(Icons.settings_outlined, color: muted),
                  ),
                ],
              ),
            ),
            Expanded(child: IndexedStack(index: tab, children: pages)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF101A2A),
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'History'),
          NavigationDestination(icon: Icon(Icons.tune), selectedIcon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }

  Widget homePage() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      const Text('Your screen history', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Capture supported screen activity with your permission.', style: TextStyle(color: muted)),
      const SizedBox(height: 22),
      Card(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(
              color: recording ? (paused ? Colors.amber : Colors.greenAccent) : muted,
              shape: BoxShape.circle,
            )),
            const SizedBox(width: 9),
            Text(recording ? (paused ? 'PAUSED' : 'RECORDING') : 'NOT RECORDING',
              style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 12)),
            const Spacer(),
            const Icon(Icons.shield_outlined, color: muted, size: 18),
          ]),
          const SizedBox(height: 22),
          Text(recording ? (paused ? 'Capture paused' : 'Capture is active') : 'Ready when you are',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(status, style: const TextStyle(color: muted, fontSize: 13)),
          const SizedBox(height: 22),
          if (!recording)
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: start,
              icon: const Icon(Icons.fiber_manual_record),
              label: const Text('Start screen recording'),
              style: FilledButton.styleFrom(backgroundColor: blue, padding: const EdgeInsets.symmetric(vertical: 16)),
            ))
          else
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: togglePause,
                icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                label: Text(paused ? 'Resume' : 'Pause'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              )),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                onPressed: stop,
                icon: const Icon(Icons.stop),
                label: const Text('Stop & save'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB94155), padding: const EdgeInsets.symmetric(vertical: 14)),
              )),
            ]),
          const SizedBox(height: 14),
          const Text('Android displays its required recording notification and system capture indicator. iOS recording is not yet implemented in this starter.',
            style: TextStyle(color: muted, fontSize: 11, height: 1.4)),
        ]),
      )),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _statCard('SAVED VIDEOS', '${recordings.length}', Icons.video_collection_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('STORAGE POLICY', 'Choose in Settings', Icons.storage_outlined)),
      ]),
      const SizedBox(height: 22),
      Row(children: [
        const Text('Recent recordings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton(onPressed: () => setState(() => tab = 1), child: const Text('See all')),
      ]),
      if (recordings.isEmpty)
        const _EmptyState(icon: Icons.video_library_outlined, title: 'No recordings yet', detail: 'Your saved screen recordings will appear here.')
      else
        ...recordings.take(3).map((r) => _recordingTile(r)),
    ],
  );

  Widget libraryPage() => RefreshIndicator(
    onRefresh: refresh,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text('Library', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Your recordings, stored on this device.', style: TextStyle(color: muted)),
        const SizedBox(height: 18),
        if (loading) const Center(child: Padding(
          padding: EdgeInsets.all(30), child: CircularProgressIndicator(),
        )) else if (recordings.isEmpty)
          const _EmptyState(icon: Icons.video_library_outlined, title: 'Your library is empty', detail: 'Start a recording to see it here.')
        else
          ...recordings.map(_recordingTile),
      ],
    ),
  );

  Widget historyPage() {
    final groups = <String, List<RecordingFile>>{};
    for (final r in recordings) {
      final d = r.createdAt;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(r);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text('History', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Browse saved recordings by day.', style: TextStyle(color: muted)),
        const SizedBox(height: 18),
        if (groups.isEmpty)
          const _EmptyState(icon: Icons.calendar_month_outlined, title: 'No history yet', detail: 'Your daily recording history will appear here.')
        else
          ...groups.entries.map((entry) => Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('${entry.value.length} recording(s)', style: const TextStyle(color: muted)),
              ...entry.value.map(_recordingTile),
            ]),
          ))),
      ],
    );
  }

  Widget settingsPage() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      const Text('Settings', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Manage your storage preference and privacy.', style: TextStyle(color: muted)),
      const SizedBox(height: 18),
      const _SettingsSection(title: 'Recording quality'),
      _SettingsTile(title: 'Resolution', subtitle: '720p baseline in this starter', icon: Icons.high_quality_outlined),
      _SettingsTile(title: 'Frame rate', subtitle: '30 FPS baseline', icon: Icons.speed_outlined),
      _SettingsTile(title: 'Audio capture', subtitle: 'Off by default', icon: Icons.mic_off_outlined),
      const SizedBox(height: 14),
      const _SettingsSection(title: 'Storage management'),
      FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snap) {
          final value = snap.data?.getString('storage_policy') ?? 'ask';
          return Card(child: Column(children: [
            RadioListTile<String>(
              value: 'cleanup', groupValue: value,
              title: const Text('Automatic cleanup (not active yet)'),
              subtitle: const Text('Saves this preference; automatic deletion is not implemented in this build.'),
              onChanged: (v) async {
                final p = await SharedPreferences.getInstance();
                await p.setString('storage_policy', v!);
                if (mounted) setState(() {});
              },
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              value: 'stop', groupValue: value,
              title: const Text('Stop at storage limit (not active yet)'),
              subtitle: const Text('Saves this preference; storage-limit monitoring is not implemented yet.'),
              onChanged: (v) async {
                final p = await SharedPreferences.getInstance();
                await p.setString('storage_policy', v!);
                if (mounted) setState(() {});
              },
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              value: 'ask', groupValue: value,
              title: const Text('Ask me / decide later'),
              subtitle: const Text('Keep recordings until you delete them manually.'),
              onChanged: (v) async {
                final p = await SharedPreferences.getInstance();
                await p.setString('storage_policy', v!);
                if (mounted) setState(() {});
              },
            ),
          ]));
        },
      ),
      const SizedBox(height: 14),
      const _SettingsSection(title: 'Privacy and permissions'),
      const _SettingsTile(title: 'Local storage', subtitle: 'Recordings stay in app-private storage by default.', icon: Icons.lock_outline),
      const _SettingsTile(title: 'System indicators', subtitle: 'Required recording indicators remain enabled.', icon: Icons.notifications_active_outlined),
      const _SettingsTile(title: 'Protected content', subtitle: 'Content blocked by the OS is not captured.', icon: Icons.privacy_tip_outlined),
      const SizedBox(height: 14),
      const _SettingsSection(title: 'About'),
      const _SettingsTile(title: 'REPLAY starter', subtitle: 'Android capture baseline · iOS capture not yet implemented', icon: Icons.info_outline),
    ],
  );

  Widget _statCard(String label, String value, IconData icon) => Card(child: Padding(
    padding: const EdgeInsets.all(15),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: blue),
      const SizedBox(height: 13),
      Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: muted, fontSize: 10, letterSpacing: .8)),
    ]),
  ));

  Widget _recordingTile(RecordingFile r) => Card(
    child: ListTile(
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: blue.withOpacity(.14), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.play_circle_outline, color: blue),
      ),
      title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${r.dateLabel}  ·  ${r.sizeLabel}', style: const TextStyle(color: muted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: muted),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RecordingDetail(recording: r, onDeleted: refresh),
      )),
    ),
  );
}

class RecordingDetail extends StatefulWidget {
  final RecordingFile recording;
  final Future<void> Function() onDeleted;
  const RecordingDetail({super.key, required this.recording, required this.onDeleted});

  @override
  State<RecordingDetail> createState() => _RecordingDetailState();
}

class _RecordingDetailState extends State<RecordingDetail> {
  VideoPlayerController? _controller;
  bool _initializing = true;
  String? _playbackError;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final file = File(widget.recording.path);
    if (!await file.exists()) {
      if (mounted) setState(() {
        _initializing = false;
        _playbackError = 'This recording file could not be found.';
      });
      return;
    }

    final controller = VideoPlayerController.file(file);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (mounted) setState(() => _initializing = false);
    } catch (e) {
      await controller.dispose();
      if (mounted) setState(() {
        _initializing = false;
        _playbackError = 'Unable to play this video. The recording may be incomplete or unsupported.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _durationLabel(Duration duration) {
    String two(int value) => value.toString().padLeft(2, '0');
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Recording')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: controller?.value.isInitialized == true
                  ? controller!.value.aspectRatio
                  : 16 / 9,
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: _initializing
                    ? const CircularProgressIndicator()
                    : _playbackError != null
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_playbackError!, textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70)),
                          )
                        : VideoPlayer(controller!),
              ),
            ),
          ),
          if (controller?.value.isInitialized == true) ...[
            const SizedBox(height: 12),
            Row(children: [
              IconButton.filled(
                onPressed: () async {
                  if (controller!.value.isPlaying) {
                    await controller!.pause();
                  } else {
                    await controller!.play();
                  }
                  if (mounted) setState(() {});
                },
                icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              Expanded(
                child: VideoProgressIndicator(
                  controller!,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller!,
                builder: (context, value, _) => Text(
                  '${_durationLabel(value.position)} / ${_durationLabel(value.duration)}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 20),
          Text(widget.recording.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          Text(widget.recording.dateLabel, style: const TextStyle(color: muted)),
          Text(widget.recording.sizeLabel, style: const TextStyle(color: muted)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final file = File(widget.recording.path);
                if (await file.exists()) {
                  await file.delete();
                  await widget.onDeleted();
                  if (context.mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete recording'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _EmptyState({required this.icon, required this.title, required this.detail});
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
    child: Column(children: [
      Icon(icon, size: 42, color: muted),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: muted)),
    ]),
  ));
}

class _SettingsSection extends StatelessWidget {
  final String title;
  const _SettingsSection({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(title.toUpperCase(), style: const TextStyle(color: blue, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
  );
}

class _SettingsTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const _SettingsTile({required this.title, required this.subtitle, required this.icon});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: Icon(icon, color: muted),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
  ));
}
