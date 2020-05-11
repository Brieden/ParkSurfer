import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'dart:convert';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;

class Park {
  final int id;
  final int capacity;
  int demand;
  final String name;
  final num centerPositionLon;
  final num centerPositionLat;

  Park(
      {this.id,
      this.capacity,
      this.demand,
      this.centerPositionLat,
      this.centerPositionLon,
      this.name});

  factory Park.fromJson(Map<String, dynamic> json) {
    return Park(
      id: json['ID'] as int,
      capacity: json['Capacity'] as int,
      demand: json['Demand'] as int,
      name: json['Name'] as String,
      centerPositionLat: json['CenterPositionLat'] as num,
      centerPositionLon: json['CenterPositionLon'] as num,
    );
  }
}

List<Park> parseParks(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Park>((json) => Park.fromJson(json)).toList();
}

Future wait(int seconds) {
  return new Future.delayed(Duration(seconds: seconds), () => {});
}

var path = "assets/Costa_Rica.json";

Future<String> _loadAParkAsset() async {
  return await rootBundle.loadString(path);
}

Future<List<Park>> _loadPark() async {
  String jsonString = await _loadAParkAsset();
  print('JSON Loaded');
  return compute(parseParks, jsonString);
}

void main() => runApp(ParkSurferHome());

class ParkSurferHome extends StatelessWidget {
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

class MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<LatLng> tappedPoints = [];
  static LatLng costaRica = LatLng(9.95, -84);
  static LatLng cartago = LatLng(9.8575, -83.921);
  static LatLng switzerland = LatLng(46.8, 8.233333);

  MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final _latTween = Tween<double>(
        begin: mapController.center.latitude, end: destLocation.latitude);
    final _lngTween = Tween<double>(
        begin: mapController.center.longitude, end: destLocation.longitude);
    final _zoomTween = Tween<double>(begin: mapController.zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    var controller = AnimationController(
        duration: const Duration(milliseconds: 10000), vsync: this); //500
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      mapController.move(
          LatLng(_latTween.evaluate(animation), _lngTween.evaluate(animation)),
          _zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  var circleMarker = <CircleMarker>[];
  var markers = <Marker>[];

  void newSnackBar(einPark) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      backgroundColor: Colors.green.shade400,
      content: Card(
        color: Colors.green.shade900,
        margin: EdgeInsets.all(0),
        child: ListTile(
          leading: Icon(
            Icons.person_add,
            color: Colors.green.shade300,
            size: 72,
          ),
          onTap: () {
            print("Booked");
            einPark.demand += 1;
            _scaffoldKey.currentState.hideCurrentSnackBar();
            newSnackBar(einPark);
          },
          title: einPark.name.isEmpty ? Text('Park') : Text(einPark.name),
          subtitle: Text("Capacity: " +
              einPark.capacity.toString() +
              " Demand: " +
              einPark.demand.toString() +
              "\nClick to Book"),
          isThreeLine: true,
        ),
      ),
      duration: Duration(seconds: 3),
    ));
  }

  void _addMarkerFromList(parkList) {
    for (Park einPark in parkList) {
      markers.add(Marker(
        width: 50.0,
        height: 50.0,
        point: LatLng(einPark.centerPositionLon, einPark.centerPositionLat),
        anchorPos: AnchorPos.align(AnchorAlign.top),
        builder: (ctx) => Container(
            child: GestureDetector(
          onTap: () {
            print('on Tap marker');
            newSnackBar(einPark);
          },
          child: Icon(
            Icons.person_pin_circle,
            size: 50.0,
            color: Colors.green.withOpacity(0.7),
          ),
        )),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ParkSurfer'),
        backgroundColor: Colors.green.shade700,
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.green.shade200,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Image(
                  image: AssetImage('images/logo_with_text.png'),
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                ),
              ),
              ExpansionTile(
                title: Text("Latin America"),
                backgroundColor: Colors.green.shade100,
                children: <Widget>[
                  ListTile(
                    title: Text('...'),
                    onTap: () {},
                  ),
                  ListTile(
                    title: Text('Costa Rica'),
                    onTap: () {
                      _handleTap(costaRica);
                      Navigator.pop(context);
                      _animatedMapMove(costaRica, 7.0);
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
                backgroundColor: Colors.green.shade100,
                children: <Widget>[
                  ListTile(
                    title: Text('...'),
                    onTap: () {},
                  ),
                  ListTile(
                    title: Text('Switzerland'),
                    onTap: () {
                      _animatedMapMove(switzerland, 7);
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
                    child: Text('Add Park Markers in Costa Rica'),
                    onPressed: () {
                      _animatedMapMove(cartago, 13);
                      _loadPark().then((value) {
                        _addMarkerFromList(value);
                      });
                    },
                  ),
                ],
              ),
            ),
            Flexible(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: costaRica,
                  zoom: 2,
                ),
                layers: [
                  TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c']),
                  MarkerLayerOptions(markers: markers),
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
