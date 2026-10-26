import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/table.dart';

class TableViewToggle extends StatelessWidget {
  const TableViewToggle(
      {super.key, required this.map, required this.onChanged});
  final bool map;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
                value: false,
                icon: Icon(Icons.grid_view),
                label: Text('Thường')),
            ButtonSegment(
                value: true,
                icon: Icon(Icons.map_outlined),
                label: Text('Sơ đồ')),
          ],
          selected: {map},
          onSelectionChanged: (value) => onChanged(value.first),
        ),
      );
}

class MapSpot {
  const MapSpot(this.code, this.x, this.y, this.w, this.h);
  final String code;
  final double x, y, w, h;
}

const restaurantMapSpots = <List<MapSpot>>[
  [
    MapSpot('B01', .270, .166, .156, .091),
    MapSpot('B02', .613, .166, .157, .091),
    MapSpot('B03', .263, .322, .172, .096),
    MapSpot('B04', .606, .324, .174, .094),
    MapSpot('B05', .262, .491, .174, .102),
    MapSpot('B06', .613, .497, .158, .093),
    MapSpot('B07', .194, .677, .137, .098),
    MapSpot('B08', .420, .677, .189, .098),
    MapSpot('B09', .702, .677, .147, .098),
  ],
  [
    MapSpot('P01', .159, .094, .098, .141),
    MapSpot('A01', .133, .325, .073, .095),
    MapSpot('A02', .133, .516, .073, .095),
    MapSpot('A03', .148, .694, .104, .144),
    MapSpot('A04', .462, .119, .075, .092),
    MapSpot('A05', .792, .326, .074, .094),
    MapSpot('A06', .447, .692, .105, .146),
    MapSpot('A07', .743, .093, .100, .142),
    MapSpot('A08', .792, .516, .074, .095),
    MapSpot('A09', .698, .745, .072, .100),
    MapSpot('A10', .849, .745, .072, .100),
  ],
  [
    MapSpot('S01', .099, .376, .122, .083),
    MapSpot('S02', .332, .376, .123, .083),
    MapSpot('S03', .103, .545, .133, .086),
    MapSpot('S04', .339, .546, .133, .085),
    MapSpot('S05', .661, .127, .168, .109),
    MapSpot('S06', .670, .322, .171, .112),
    MapSpot('S07', .688, .489, .138, .076),
    MapSpot('S08', .665, .633, .169, .084),
    MapSpot('S09', .128, .727, .122, .080),
    MapSpot('S10', .360, .726, .148, .081),
  ],
];

/// Presentation configuration only. IDs must be explicitly assigned by an admin.
/// Never infer a business table from the printed code or list order.
class RestaurantMapView extends StatefulWidget {
  const RestaurantMapView(
      {super.key,
      required this.tables,
      required this.onTableTap,
      this.configure = false});
  final bool configure;
  final List<DiningTable> tables;
  final ValueChanged<DiningTable> onTableTap;

  @override
  State<RestaurantMapView> createState() => _RestaurantMapViewState();
}

class _RestaurantMapViewState extends State<RestaurantMapView> {
  int _map = 0;
  Map<String, int> _links = {};
  bool _ready = false;
  static const _key = 'restaurant_map_table_links_map_replacement_v2';

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonDecode(prefs.getString(_key) ??
              await rootBundle.loadString('assets/maps/table_links.json'))
          as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _links = raw.map((key, value) => MapEntry(key, value as int));
        for (final entry in _links.entries) {
          if (widget.tables.any((table) => table.id == entry.value)) {
            _map = int.parse(entry.key.split(':').first);
            break;
          }
        }
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  String _spotKey(MapSpot spot) => '$_map:${spot.code}';

  DiningTable? _table(MapSpot spot) {
    final id = _links[_spotKey(spot)];
    for (final table in widget.tables) {
      if (table.id == id) return table;
    }
    return null;
  }

  Future<void> _link(MapSpot spot) async {
    final key = _spotKey(spot);
    final selected = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
              title: Text('Liên kết vị trí ${spot.code}'),
              children: [
                const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        'Chọn bàn thuộc bộ lọc hiện tại. Cấu hình chỉ lưu trên thiết bị này.')),
                SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, -1),
                    child: const Text('Bỏ liên kết')),
                for (final table in widget.tables)
                  if (!_links.entries.any((entry) =>
                      entry.key != key &&
                      entry.key.startsWith('$_map:') &&
                      entry.value == table.id))
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, table.id),
                      child: Text(
                          '${table.name} • ${table.code ?? "Không có mã"} • ${table.capacity ?? "?"} ghế (ID ${table.id})'),
                    ),
              ],
            ));
    if (selected == null || !mounted) return;
    final updated = Map<String, int>.from(_links);
    if (selected == -1) {
      updated.remove(key);
    } else {
      updated[key] = selected;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(_key, jsonEncode(updated));
      if (!saved) throw StateError('Không thể lưu cấu hình');
      if (mounted) setState(() => _links = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể lưu liên kết: $error')));
      }
    }
  }

  Color _color(String? status) => switch (status) {
        'free' => Colors.green,
        'occupied' => Colors.orange,
        'cleaning' => Colors.grey,
        _ => Colors.blueGrey,
      };

  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
                child: DropdownButton<int>(
              isExpanded: true,
              value: _map,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Khu bàn ăn')),
                DropdownMenuItem(value: 1, child: Text('Phòng bao')),
                DropdownMenuItem(value: 2, child: Text('Sân vườn')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _map = value;
                  _transform.value = Matrix4.identity();
                });
              },
            )),
            TextButton.icon(
              onPressed: () => _transform.value = Matrix4.identity(),
              icon: const Icon(Icons.fit_screen),
              label: const Text('Vừa màn hình'),
            ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text('🟩 Trống   🟧 Đang dùng   ◼ Đang dọn'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
              'Kéo hoặc phóng to sơ đồ. Nhấn giữ vị trí trong Quản lý bàn để liên kết (lưu trên thiết bị).'),
        ),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final ratio = _map == 1 ? 1.5 : 2 / 3;
          final width = constraints.maxWidth < constraints.maxHeight * ratio
              ? constraints.maxWidth
              : constraints.maxHeight * ratio;
          final height = width / ratio;
          return InteractiveViewer(
            transformationController: _transform,
            minScale: 1,
            maxScale: 4,
            child: Center(
                child: SizedBox(
                    width: width,
                    height: height,
                    child: Stack(children: [
                      Positioned.fill(
                          child: Image.asset('assets/maps/map${_map + 1}.png',
                              fit: BoxFit.fill)),
                      for (final spot in restaurantMapSpots[_map])
                        Positioned(
                          left: spot.x * width,
                          top: spot.y * height,
                          width: spot.w * width,
                          height: spot.h * height,
                          child: Tooltip(
                            message: _table(spot) == null
                                ? '${spot.code}: chưa liên kết hoặc ngoài bộ lọc'
                                : '${spot.code} → ${_table(spot)!.name} • ${_table(spot)!.status}',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onLongPress: widget.configure && _ready
                                  ? () => _link(spot)
                                  : null,
                              onTap: !_ready
                                  ? null
                                  : () {
                                      final table = _table(spot);
                                      if (table != null) {
                                        widget.onTableTap(table);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Vị trí này chưa được liên kết với bàn hoặc bàn nằm ngoài bộ lọc')));
                                      }
                                    },
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.blueGrey
                                            .withValues(alpha: .6)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _table(spot) == null
                                      ? null
                                      : Align(
                                          alignment: Alignment.topRight,
                                          child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: _color(
                                                    _table(spot)!.status),
                                                border: Border.all(
                                                    color: Colors.white),
                                              )),
                                        )),
                            ),
                          ),
                        ),
                    ]))),
          );
        })),
      ]);
}
