import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const MemoryHierarchyApp());

class MemoryHierarchyApp extends StatelessWidget {
  const MemoryHierarchyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Hierarchy Visualizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Arial'),
      home: const MemoryHierarchyScreen(),
    );
  }
}

class MemoryHierarchyScreen extends StatefulWidget {
  const MemoryHierarchyScreen({super.key});

  @override
  State<MemoryHierarchyScreen> createState() => _MemoryHierarchyScreenState();
}

class _MemoryHierarchyScreenState extends State<MemoryHierarchyScreen>
    with TickerProviderStateMixin {
  late final AnimationController pulse;
  late final AnimationController flow;

  String target = '';
  String activeNode = '';
  String resultNode = '';
  int activeSegment = -1;
  int step = 0;
  bool running = false;

  String currentTitle = 'Ready to simulate';
  String currentMessage =
      'Choose a simulation button. The diagram will animate the path the CPU follows to find the data.';

  final Map<String, Offset> centers = const {
    'CPU': Offset(0.13, 0.46),
    'CACHE': Offset(0.45, 0.25),
    'RAM': Offset(0.45, 0.49),
    'SSD': Offset(0.45, 0.74),
    'RESULT': Offset(0.78, 0.49),
  };

  @override
  void initState() {
    super.initState();
    pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    flow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void dispose() {
    pulse.dispose();
    flow.dispose();
    super.dispose();
  }

  Future<void> runSimulation(String selected) async {
    if (running) return;
    setState(() {
      target = selected;
      resultNode = '';
      activeSegment = -1;
      activeNode = 'CPU';
      running = true;
      step = 1;
      currentTitle = 'Step 1: CPU requests data';
      currentMessage = 'The CPU starts by asking for the data needed to run an instruction.';
    });
    await Future.delayed(const Duration(milliseconds: 700));

    await travelTo('CACHE', 0, 'Step 2: Checking CACHE...',
        'Cache is checked first because it is the fastest memory.');
    if (selected == 'CACHE') {
      await found('CACHE', 'Data Found in CACHE!',
          'Shortest path: CPU → Cache → Result. This is called a cache hit.');
      return;
    }

    await waitStep('CACHE MISS',
        'The data was not in cache, so the CPU continues to RAM.');
    await travelTo('RAM', 1, 'Step 3: Checking RAM...',
        'RAM is slower than cache but faster than SSD/storage.');
    if (selected == 'RAM') {
      await found('RAM', 'Data Found in RAM!',
          'Medium path: CPU → Cache → RAM → Result.');
      return;
    }

    await waitStep('RAM MISS',
        'The data was not in RAM, so the system checks SSD/storage last.');
    await travelTo('SSD', 2, 'Step 4: Checking SSD...',
        'SSD/storage is checked last because it has the longest access time.');
    await found('SSD', 'Data Found in SSD!',
        'Longest path: CPU → Cache → RAM → SSD → Result.');
  }

  Future<void> travelTo(
      String node, int segment, String title, String message) async {
    setState(() {
      activeSegment = segment;
      currentTitle = title;
      currentMessage = message;
      step++;
    });
    await flow.forward(from: 0);
    setState(() => activeNode = node);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> waitStep(String title, String message) async {
    setState(() {
      currentTitle = title;
      currentMessage = message;
      step++;
    });
    await Future.delayed(const Duration(milliseconds: 750));
  }

  Future<void> found(String node, String title, String message) async {
    setState(() {
      resultNode = node;
      activeNode = node;
      activeSegment = 3;
      currentTitle = title;
      currentMessage = message;
      step++;
    });
    await flow.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      activeSegment = -1;
      running = false;
    });
  }

  void reset() {
    setState(() {
      target = '';
      activeNode = '';
      resultNode = '';
      activeSegment = -1;
      running = false;
      step = 0;
      currentTitle = 'Ready to simulate';
      currentMessage =
          'Choose a simulation button. The diagram will animate the path the CPU follows to find the data.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff06101f),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff06101f), Color(0xff0c1b31), Color(0xff06101f)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 900;
              return Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    header(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 7, child: diagramPanel()),
                                const SizedBox(width: 18),
                                SizedBox(width: 455, child: rightPanel()),
                              ],
                            )
                          : ListView(
                              children: [
                                SizedBox(height: 620, child: diagramPanel()),
                                const SizedBox(height: 18),
                                rightPanel(),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget header() {
    return Row(
      children: [
        neonIcon(Icons.memory, Colors.cyanAccent, big: true),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Memory Hierarchy Visualizer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('Visualize how CPU searches data from fastest to slowest memory',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 15)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.45)),
          ),
          child: Row(
            children: [
              Icon(running ? Icons.sync : Icons.check_circle_outline,
                  color: running ? Colors.amberAccent : Colors.greenAccent, size: 19),
              const SizedBox(width: 8),
              Text(running ? 'RUNNING' : 'READY',
                  style: TextStyle(
                      color: running ? Colors.amberAccent : Colors.greenAccent,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    );
  }

  Widget diagramPanel() {
    return glass(
      padding: EdgeInsets.zero,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulse, flow]),
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: CircuitPainter(
                  centers: centers,
                  pulse: pulse.value,
                  flow: flow.value,
                  activeSegment: activeSegment,
                  activeNode: activeNode,
                  resultNode: resultNode,
                ),
              ),
            ),
            Positioned(left: 24, top: 24, child: sectionLabel('DATA SEARCH PATH', Icons.hub)),
            node('CPU', 'CPU', 'Requests Data', Icons.memory, Colors.cyanAccent),
            node('CACHE', 'CACHE', 'L1 / L2 Cache\nFastest / Smallest', Icons.bolt, Colors.amberAccent),
            node('RAM', 'RAM', 'Main Memory\nFast / Temporary', Icons.view_module, Colors.greenAccent),
            node('SSD', 'SSD', 'Secondary Storage\nSlow / Permanent', Icons.sd_storage, Colors.purpleAccent),
            resultNodeWidget(),
            Positioned(left: 24, right: 24, bottom: 28, child: pathTaken()),
          ],
        ),
      ),
    );
  }

  Widget node(String keyName, String title, String subtitle, IconData icon, Color color) {
    final c = centers[keyName]!;
    final active = activeNode == keyName || resultNode == keyName;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, b) {
          final w = keyName == 'CPU' ? 210.0 : 250.0;
          final h = keyName == 'CPU' ? 104.0 : 118.0;
          return Stack(
            children: [
              Positioned(
                left: b.maxWidth * c.dx - w / 2,
                top: b.maxHeight * c.dy - h / 2,
                width: w,
                height: h,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: active ? color.withOpacity(0.18) : Colors.white.withOpacity(0.055),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? color : Colors.white.withOpacity(0.12), width: active ? 2.2 : 1),
                    boxShadow: active
                        ? [BoxShadow(color: color.withOpacity(0.38 + pulse.value * .2), blurRadius: 28, spreadRadius: 2)]
                        : [],
                  ),
                  child: Row(
                    children: [
                      neonIcon(icon, color),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(title,
                                  maxLines: 1,
                                  style: TextStyle(color: color, fontSize: 21, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(height: 6),
                            Text(subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.25)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget resultNodeWidget() {
    final c = centers['RESULT']!;
    final hasResult = resultNode.isNotEmpty;
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, b) {
          const w = 220.0;
          const h = 150.0;
          return Stack(
            children: [
              Positioned(
                left: b.maxWidth * c.dx - w / 2,
                top: b.maxHeight * c.dy - h / 2,
                width: w,
                height: h,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasResult ? Colors.greenAccent.withOpacity(0.14) : Colors.white.withOpacity(0.045),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: hasResult ? Colors.greenAccent : Colors.white.withOpacity(0.12), width: hasResult ? 2.2 : 1),
                    boxShadow: hasResult
                        ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.28), blurRadius: 26, spreadRadius: 2)]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(hasResult ? Icons.check_circle : Icons.hourglass_bottom,
                          color: hasResult ? Colors.greenAccent : Colors.white54, size: 42),
                      const SizedBox(height: 8),
                      Text('RESULT',
                          style: TextStyle(
                              color: hasResult ? Colors.greenAccent : Colors.white54,
                              fontWeight: FontWeight.w900,
                              fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(hasResult ? 'Data Found in $resultNode' : 'Waiting for data',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.25)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget pathTaken() {
    final pieces = target.isEmpty
        ? ['CPU', 'CACHE', 'RAM', 'SSD', 'RESULT']
        : target == 'CACHE'
            ? ['CPU', 'CACHE', 'RESULT']
            : target == 'RAM'
                ? ['CPU', 'CACHE MISS', 'RAM', 'RESULT']
                : ['CPU', 'CACHE MISS', 'RAM MISS', 'SSD', 'RESULT'];
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.route, color: Colors.cyanAccent),
            const SizedBox(width: 12),
            const Text('Path Taken:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900)),
            const SizedBox(width: 16),
            for (int i = 0; i < pieces.length; i++) ...[
              chip(pieces[i]),
              if (i != pieces.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward, color: Colors.white70, size: 18),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget rightPanel() {
    return SingleChildScrollView(
      child: Column(
        children: [
          controls(),
          const SizedBox(height: 14),
          currentStep(),
          const SizedBox(height: 14),
          speedPanel(),
        ],
      ),
    );
  }

  Widget controls() {
    return glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.sports_esports, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text('SIMULATION CONTROLS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          controlButton('Data is in CACHE', 'Shortest path: CPU → Cache', Icons.bolt, Colors.amberAccent, () => runSimulation('CACHE')),
          controlButton('Data is in RAM', 'Medium path: CPU → Cache → RAM', Icons.view_module, Colors.greenAccent, () => runSimulation('RAM')),
          controlButton('Data is in SSD', 'Longest path: CPU → Cache → RAM → SSD', Icons.sd_storage, Colors.purpleAccent, () => runSimulation('SSD')),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset Simulation', style: TextStyle(fontWeight: FontWeight.w900)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.22)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget controlButton(String label, String sub, IconData icon, Color color, VoidCallback onTap) {
    final selected = target.isNotEmpty && label.toUpperCase().contains(target);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: running ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.16) : Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? color : Colors.white.withOpacity(0.12), width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              neonIcon(icon, color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.play_arrow_rounded, color: color, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  Widget currentStep() {
    return glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bubble_chart, color: Colors.cyanAccent),
              SizedBox(width: 10),
              Text('CURRENT STEP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text(currentMessage,
                          style: const TextStyle(color: Colors.white, height: 1.35, fontSize: 13.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 42, height: 42, child: running ? const CircularProgressIndicator(strokeWidth: 4) : const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget speedPanel() {
    return glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timer_outlined, color: Colors.white70),
              SizedBox(width: 10),
              Text('MEMORY SPEED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              SizedBox(width: 6),
              Expanded(child: Text('(Access Time)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              speedCard('CACHE', '~ 1 ns', 'Fastest', Icons.bolt, Colors.amberAccent),
              const SizedBox(width: 10),
              speedCard('RAM', '~ 10 ns', 'Fast', Icons.view_module, Colors.greenAccent),
              const SizedBox(width: 10),
              speedCard('SSD', '~ 100,000 ns', 'Slowest', Icons.sd_storage, Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('Order: Cache is fastest → RAM is next → SSD is slowest.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget speedCard(String name, String time, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 135,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.55)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            Icon(icon, color: color, size: 22),
            FittedBox(
              child: Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionLabel(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 24),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }

  Widget neonIcon(IconData icon, Color color, {bool big = false}) {
    return Container(
      width: big ? 62 : 52,
      height: big ? 62 : 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(big ? 18 : 14),
        border: Border.all(color: color.withOpacity(0.32)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.10), blurRadius: 18)],
      ),
      child: Icon(icon, color: color, size: big ? 34 : 28),
    );
  }

  Widget chip(String text) {
    Color color = Colors.cyanAccent;
    if (text.contains('CACHE')) color = Colors.amberAccent;
    if (text.contains('RAM')) color = Colors.greenAccent;
    if (text.contains('SSD')) color = Colors.purpleAccent;
    if (text.contains('RESULT')) color = Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
    );
  }

  Widget glass({required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.065),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: child,
    );
  }
}

class CircuitPainter extends CustomPainter {
  final Map<String, Offset> centers;
  final double pulse;
  final double flow;
  final int activeSegment;
  final String activeNode;
  final String resultNode;

  CircuitPainter({
    required this.centers,
    required this.pulse,
    required this.flow,
    required this.activeSegment,
    required this.activeNode,
    required this.resultNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    final cpu = p('CPU', size);
    final cache = p('CACHE', size);
    final ram = p('RAM', size);
    final ssd = p('SSD', size);
    final result = p('RESULT', size);

    final base = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..shader = const LinearGradient(colors: [Colors.cyanAccent, Colors.greenAccent]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    drawWire(canvas, base, cpu, cache);
    drawWire(canvas, base, cache, ram);
    drawWire(canvas, base, ram, ssd);
    drawWire(canvas, base, cache, result);
    drawWire(canvas, base, ram, result);
    drawWire(canvas, base, ssd, result);

    final segments = <List<Offset>>[
      [cpu, cache],
      [cache, ram],
      [ram, ssd],
      [resultStart(size), result],
    ];
    if (activeSegment >= 0 && activeSegment < segments.length) {
      final s = segments[activeSegment];
      drawWire(canvas, active, s[0], s[1]);
      drawPacket(canvas, s[0], s[1]);
    }

    for (final point in [cpu, cache, ram, ssd, result]) {
      canvas.drawCircle(point, 5, Paint()..color = Colors.white.withOpacity(0.22));
    }
  }

  Offset p(String key, Size s) => Offset(centers[key]!.dx * s.width, centers[key]!.dy * s.height);

  Offset resultStart(Size s) {
    if (resultNode == 'CACHE' || activeNode == 'CACHE') return p('CACHE', s);
    if (resultNode == 'RAM' || activeNode == 'RAM') return p('RAM', s);
    if (resultNode == 'SSD' || activeNode == 'SSD') return p('SSD', s);
    return p('CPU', s);
  }

  void drawGrid(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.035)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void drawWire(Canvas canvas, Paint paint, Offset a, Offset b) {
    final midX = (a.dx + b.dx) / 2;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(midX, a.dy)
      ..lineTo(midX, b.dy)
      ..lineTo(b.dx, b.dy);
    canvas.drawPath(path, paint);
  }

  void drawPacket(Canvas canvas, Offset a, Offset b) {
    final midX = (a.dx + b.dx) / 2;
    final points = [a, Offset(midX, a.dy), Offset(midX, b.dy), b];
    final distances = <double>[];
    double total = 0;
    for (int i = 0; i < 3; i++) {
      final d = (points[i + 1] - points[i]).distance;
      distances.add(d);
      total += d;
    }
    double remain = flow * total;
    Offset pos = a;
    for (int i = 0; i < 3; i++) {
      if (remain <= distances[i]) {
        pos = Offset.lerp(points[i], points[i + 1], remain / distances[i])!;
        break;
      }
      remain -= distances[i];
      pos = points[i + 1];
    }
    canvas.drawCircle(pos, 18 + pulse * 7, Paint()..color = Colors.cyanAccent.withOpacity(0.18));
    canvas.drawCircle(pos, 11, Paint()..color = Colors.cyanAccent);
    canvas.drawCircle(pos, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CircuitPainter oldDelegate) => true;
}
