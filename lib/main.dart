import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (c)=>TodoProveedor(),
        child: HomePage(),
      ),
      theme: ThemeData(primarySwatch: Colors.purple),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key,}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final backdropSize = 0.5;
  final countries = ["ad.png", "mx.png", "pe.png", "ca.png", "ar.png"];
  int loadedImage = 0;
  late Image imagen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) =>
      Provider.of<TodoProveedor>(context, listen: false).refresh()
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      appBar: BackdropAppBar(
        title: Text('La frase diaria'),
        actions: [BackdropToggleButton(
          icon: AnimatedIcons.list_view,
        )],
      ),
      frontLayer: Center(
        child: Container(
          child: Consumer<TodoProveedor>(
            builder: (context, provider, child) {
              if(provider.image.isEmpty)
                return Center(child: CircularProgressIndicator(),);
              imagen = Image.network(provider.image,fit: BoxFit.fill,);
              if(loadedImage == 0){
                loadedImage = 1;
                imagen.image.resolve(new ImageConfiguration()).addListener(ImageStreamListener((_,__){
                  if(mounted)
                    setState(() => loadedImage = 2);
                }));
              }
              if(provider.quote.isEmpty || provider.time.isEmpty || loadedImage<2)
                return Center(child: CircularProgressIndicator(),);

              return Stack(
                fit: StackFit.expand,
                children:[
                  FittedBox(
                    child: imagen,
                    fit: BoxFit.fill,
                  ),
                  Container(color: Colors.black.withOpacity(0.666)),
                  Padding(
                    padding: EdgeInsets.all(15), 
                    child: Column(
                      children: [
                        Text("${TodoProveedor.countryNames[provider.selectedCountry]}", style: TextStyle(color: Colors.white, fontSize: 18),textAlign: TextAlign.center,),
                        Text("${provider.time}", style: TextStyle(color: Colors.white, fontSize: 36),textAlign: TextAlign.center,),
                      ],
                    ),
                  ),
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${provider.quote.split("♦")[0]}", style: TextStyle(color: Colors.white),),
                        Text("${provider.quote.split("♦")[1]}", style: TextStyle(color: Colors.white),),
                      ],
                    ),
                  )),
                ],
              );
            },
          ),
        ),
      ),
      backLayer: Container(
        height: MediaQuery.of(context).size.height * backdropSize * 0.75,
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          itemCount: countries.length,
          itemBuilder: (BuildContext context, int index) {
            final flagAPI = "https://flagcdn.com/16x12/";
            return ListTile(
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network('${flagAPI}${countries[index]}'),
              ),
              title: Text(TodoProveedor.countryNames[index], style: TextStyle(color: Colors.white),),
              onTap: (){
                context.read<TodoProveedor>().selectCountry(index);
                imagen.image.evict();
                loadedImage = 0;
              },
            );
          },
        ),
      ),
      headerHeight: MediaQuery.of(context).size.height * backdropSize,
    );
  }
}

class TodoProveedor with ChangeNotifier {
  String quote = "", image = "", time = "";
  int selectedCountry = 1;
  static final countries = [
    "Europe/Andorra",
    "America/Mexico_City",
    "America/Panama", //Perú
    "America/Winnipeg", //Canadá
    "America/Argentina/Buenos_Aires"
  ];
  static final countryNames = [
    "Andorra",
    "México",
    "Perú",
    "Canadá",
    "Argentina"
  ];

  void selectCountry(int country){
    selectedCountry = country;
    refresh();
  }

  void refresh(){
    quote = image = time = "";
    getImage();
    getQuote();
    getTime();
  }

  final quoteAPI = "https://zenquotes.io/api/random";
  void getQuote() async{
    try {
      Response res = await get(Uri.parse(quoteAPI));
      if(res.statusCode == HttpStatus.ok){
        final jsonResponse = jsonDecode(res.body);
        quote = '${jsonResponse[0]["q"]}♦- ${jsonResponse[0]["a"]}';
        notifyListeners();
      }
    } catch (e) {}
  }

  final imageAPI = "https://picsum.photos/v2/list";
  void getImage() async{
    try {
      Response res = await get(Uri.parse(imageAPI));
      if(res.statusCode == HttpStatus.ok){
        dynamic img = jsonDecode(res.body);
        image = img[Random().nextInt(img.length)]["download_url"];
        notifyListeners();
      }
    } catch (e) {}
  }

  final timeAPI = "http://worldtimeapi.org/api/timezone/";
  void getTime() async{
    try {
      Response res = await get(Uri.parse(timeAPI+countries[selectedCountry]));
      if(res.statusCode == HttpStatus.ok){
        time = jsonDecode(res.body)["datetime"].split("T")[1].split(".")[0];
        notifyListeners();
      }
    } catch (e) {}
  }

}
