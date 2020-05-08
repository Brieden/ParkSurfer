import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

void main() => runApp(ParkSurferHome());

class ParkSurferHome extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  @override
  MapPageState createState() {
    return MapPageState();
  }
}

class MapPageState extends State<MapPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<LatLng> tappedPoints = [];
  static LatLng cartago = LatLng(9.8575, -83.921);
  static LatLng london = LatLng(51.5, -0.09);
  static LatLng paris = LatLng(48.8566, 2.3522);
  static LatLng dublin = LatLng(53.3498, -6.2603);

  MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    var markers = tappedPoints.map((latlng) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: london,
        builder: (ctx) => Container(
            child: GestureDetector(
          onTap: () {
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text('Tapped on blue FlutterLogo Marker'),
            ));
          },
          child: FlutterLogo(),
        )),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('ParkSurfer')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Image(
                image: AssetImage('images/logo_with_text.png'),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ExpansionTile(
              title: Text("Latin America"),
              children: <Widget>[
                ListTile(
                  title: Text('...'),
                  onTap: () {},
                ),
                ListTile(
                  title: Text('Costa Rica'),
                  onTap: () {
                    _handleTap(paris);
                    Navigator.pop(context);
                    mapController.move(dublin, 5.0);
                  },
                ),
                ListTile(
                  title: Text('...'),
                  onTap: () {},
                ),
              ],
            ),
            ExpansionTile(
              title: Text("Europe"),
              children: <Widget>[
                ListTile(
                  title: Text('...'),
                  onTap: () {},
                ),
                ListTile(
                  title: Text('Switzerland'),
                  onTap: () {
                    var bounds = LatLngBounds();
                    bounds.extend(dublin);
                    bounds.extend(paris);
                    bounds.extend(london);
                    mapController.fitBounds(
                      bounds,
                      options: FitBoundsOptions(
                        padding: EdgeInsets.only(left: 15.0, right: 15.0),
                      ),
                    );

                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text('...'),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
      key: _scaffoldKey,
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Row(
                children: <Widget>[
                  MaterialButton(
                    child: Text('Dublin'),
                    onPressed: () {
                      mapController.move(dublin, 5.0);
                    },
                  ),
                ],
              ),
            ),
            Flexible(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 5.0,
                ),
                layers: [
                  TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c']),
                  MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(LatLng latlng) {
    setState(() {
      tappedPoints.add(latlng);
    });
  }
}
