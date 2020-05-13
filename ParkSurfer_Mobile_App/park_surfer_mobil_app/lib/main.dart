import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';
import 'dart:convert';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;

import 'package:geolocator/geolocator.dart';

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

var path = "assets/Costa_Rica.json";

Future<String> _loadAParkAsset(path) async {
  return await rootBundle.loadString(path);
}

Future<List<Park>> _loadPark(path) async {
  String jsonString = await _loadAParkAsset(path);
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
  static LatLng deutschland = LatLng(51.165, 10.455278);

  MapController mapController;
  final PopupController _popupController = PopupController();

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
        duration: const Duration(milliseconds: 500), vsync: this); //500
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
    while (markers.isNotEmpty) {
      markers.removeLast();
    }
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
                      _loadPark("assets/CR_parks.json").then((value) {
                        _addMarkerFromList(value);
                        setState(() {
                          markers = List.from(markers);
                        });
                      });

                      _handleTap(costaRica);
                      Navigator.pop(context);
                      _animatedMapMove(costaRica, 8);
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
                      _loadPark("assets/CH_parks.json").then((value) {
                        _addMarkerFromList(value);
                        setState(() {
                          markers = List.from(markers);
                        });
                      });
                      _animatedMapMove(switzerland, 7);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text('Germany'),
                    onTap: () {
                      _loadPark("assets/DE_parks.json").then((value) {
                        _addMarkerFromList(value);
                        setState(() {
                          markers = List.from(markers);
                        });
                      });
                      _animatedMapMove(deutschland, 5);
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        child: Icon(
          Icons.gps_fixed,
          color: Colors.white,
        ),
        onPressed: () {
          print('press');
          _getYourLocation().then((posi) => _animatedMapMove(posi, 15));
        },
      ),
      key: _scaffoldKey,
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          plugins: [
            MarkerClusterPlugin(),
          ],
          onTap: (_) => _popupController
              .hidePopup(), // Hide popup when the map is tapped.

          center: LatLng(30, -28),
          zoom: 1.8,
        ),
        layers: [
          TileLayerOptions(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c']),
          MarkerClusterLayerOptions(
            maxClusterRadius: 100, //120
            size: Size(40, 40),
            anchor: AnchorPos.align(AnchorAlign.center),
            fitBoundsOptions: FitBoundsOptions(
              padding: EdgeInsets.all(50),
            ),
            markers: markers,
            polygonOptions: PolygonOptions(
                borderColor: Colors.blueAccent,
                color: Colors.black12,
                borderStrokeWidth: 3),
            popupOptions: PopupOptions(
                popupSnap: PopupSnap.top,
                popupController: _popupController,
                popupBuilder: (_, marker) => Container(
                      width: 200,
                      height: 100,
                      color: Colors.white,
                      child: GestureDetector(
                        onTap: () => debugPrint("Popup tap!"),
                        child: Text(
                          "Container popup for marker at ${marker.point}",
                        ),
                      ),
                    )),
            builder: (context, markers) {
              return FloatingActionButton(
                child: Text(markers.length.toString()),
                onPressed: null,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<LatLng> _getYourLocation() async {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Card(
            child: ListTile(
          title: Text('try to find your location'),
          trailing: Icon(Icons.gps_fixed),
        )),
        duration: Duration(seconds: 30)));

    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    print(position);
    markers.add(
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 50,
        width: 50,
        point: LatLng(position.latitude, position.longitude),
        builder: (ctx) => Icon(
          Icons.person_pin,
          size: 50,
          color: Colors.green.shade900,
        ),
      ),
    );
    setState(() {
      markers = List.from(markers);
    });
    List<Placemark> placemark = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    var geo_code = placemark.first.isoCountryCode;
    print(geo_code);
    _scaffoldKey.currentState.hideCurrentSnackBar();
    return LatLng(position.latitude, position.longitude);
  }

  void _handleTap(LatLng latlng) {
    setState(() {
      tappedPoints.add(latlng);
    });
  }
}
