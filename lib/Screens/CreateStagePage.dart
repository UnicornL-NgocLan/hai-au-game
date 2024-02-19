import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:haiau_game2/Objects/programObject.dart';
import 'package:haiau_game2/Objects/stageObject.dart';
import 'package:haiau_game2/widgets/showNotifyAlert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:haiau_game2/Objects/userObject.dart';

class CreateStagePage extends StatefulWidget {
  CreateStagePage({Key? key}) : super(key: key);

  @override
  State<CreateStagePage> createState() => _CreateStagePageState();
}

class _CreateStagePageState extends State<CreateStagePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? programeName;
  String destinationUrl = "";
  String description = "";
  List programStage = [];
  List programList = [];
  List programNameList = [];
  List programIdList = [];
  String programId = '';
  bool isLoading = false;
  String currentProgramPassword = "";


  CollectionReference programsCollection = FirebaseFirestore.instance.collection('programs');
  CollectionReference stagesCollection = FirebaseFirestore.instance.collection('stages');
  CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  late FocusNode myFocusNode;

  @override
  void initState() {
    super.initState();
    checkForAuth();
    fetchData();
    WebView.platform = WebWebViewPlatform();
    myFocusNode = FocusNode();
  }

  @override
  void dispose(){
    super.dispose();
    myFocusNode.dispose();
    _nameController.dispose();
    _destinationController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
  }

  checkForAuth()async{
    final prefs = await SharedPreferences.getInstance();
    final List<String>? user_info = prefs.getStringList('player_auth');

    if(user_info != null){
      if(user_info[1] == 'player'){
        Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pushReplacementNamed('/waiting-room');
        });
      }else if(user_info[1] == 'porter'){
        Future.delayed(const Duration(seconds:0), () {
          Navigator.of(context).pushReplacementNamed('/admin-home');
        });
      } 
    }else{
      Future.delayed(const Duration(seconds:0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  
  handleAddDestination(){
    String newDestinationUrl = _destinationController.text;
    newDestinationUrl = newDestinationUrl.replaceAll('<iframe src="', "");
    newDestinationUrl = newDestinationUrl.replaceAll('></iframe>', "");
    newDestinationUrl = newDestinationUrl.replaceAll('" width', ' width');

    setState(() {
      destinationUrl = newDestinationUrl;
    });
  }

  fetchStageForProgram()async{
    final index = programNameList.indexOf(programeName);
    final currentProgramId = programIdList[index];

    final snapshot = await stagesCollection.where('id_program',isEqualTo: currentProgramId).orderBy('order_index').get();
    final allRelatedStages = snapshot.docs.map((doc) => Stage.fromJson(doc.data() as Map<String, dynamic>)).toList();
    
    final currentProgram = programList.where((e)=> e.name == programeName).toList();
    setState(() {
      programStage = allRelatedStages;
      programId = currentProgramId;
      currentProgramPassword = currentProgram[0].password;
    });
  }

  handleAddNewStage() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    if(_nameController.text.isEmpty || _passwordController.text.isEmpty || destinationUrl.isEmpty){
      return showDialog(
        context: context,
        builder: (context) =>const ShowNotifyAlert(type: 'Lỗi', errorText: 'Vui lòng nhập đầy đủ thông tin')
      );
    }

    setState(() {
      isLoading = true;
    });

    Stage newStage = Stage(
      programStage.length,
      _nameController.text,
      destinationUrl,
      _passwordController.text,
      programId,
      _descriptionController.text.replaceAll("\n", "/n/"),
    );

    String newStageId = stagesCollection.doc().id;
    DocumentReference refStage = stagesCollection.doc(newStageId);
    batch.set(refStage, newStage.toJson());

    String newUserId = usersCollection.doc().id;
    DocumentReference refUser = usersCollection.doc(newUserId);
    
    User newUser = User(
      "porter${generateRandomString(3)}",
      "porter${generateRandomString(5)}",
      random(100000, 999999).toString(),
      "https://res.cloudinary.com/dhrpdnd8m/image/upload/v1657729253/j6lrhf3wtvbnznp220fy.webp",
      "porter",
      programId,
      programStage.length,
      '',
      "false",
    );
    batch.set(refUser, newUser.toJson());
    
    await batch.commit();
    _nameController.clear();
    _passwordController.clear();
    _destinationController.clear();
    _descriptionController.clear();
      setState(() {
        destinationUrl = '';
        isLoading = false;
        programStage.add(newStage);
      });

    showDialog(
      context: context,
      builder: (context) =>const ShowNotifyAlert(type:'Thành công',errorText:'Đã tạo chặng thành công!')
    );
    //print(_descriptionController.text.replaceAll("\n", "/n/"));
  }

  int random(min, max) {
    return min + Random().nextInt(max - min);
  }

  String generateRandomString(int len) {
    var r = Random();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => chars[r.nextInt(chars.length)]).join();
  }

  fetchData() async {
    final snapshot = await programsCollection.get();
    final allData = snapshot.docs.map((doc) => Program.fromJson(doc.data() as Map<String, dynamic>)).toList();
    final allProgramIds = snapshot.docs.map((doc) => doc.id).toList();
    final allProgramName = snapshot.docs.map((doc) => doc['name']).toList();
    
    setState(() {
      programNameList = allProgramName;
      programList = allData; 
      programIdList = allProgramIds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child:Column(
            children: [
              //Header
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children:[
                    InkWell(
                      onTap:(){
                        Navigator.of(context).pushReplacementNamed('/admin-home');
                      },
                      child: const Icon(Icons.keyboard_return,size:30),
                    )
                  ]
                ),
              ),
              // Title
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal:20,vertical:5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:MainAxisAlignment.start,
                  children:const [
                  Text('Tạo chặng chơi',style:TextStyle(fontSize:30,color:Colors.green,fontWeight: FontWeight.w900)),
                ],),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                child:Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chọn chương trình mà bạn muốn',style:TextStyle(overflow:TextOverflow.ellipsis,fontSize:16,color:Color(0xFF1A4D2E),fontWeight: FontWeight.w800),),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical:15),
                      child:Column(
                        children: [
                          Container(
                            padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border:Border.all(
                                width:1,
                                color:Colors.grey,
                              ),
                              color: Colors.white,  
                            ),
                            child: DropdownButton<String>(
                              isDense:true,
                              underline: const SizedBox(),
                              borderRadius: BorderRadius.circular(10),
                              focusColor: Colors.white,
                              hint: const Text('Chọn chương trình'),
                              value:programeName,
                              isExpanded: true,
                              items: <String>[...programNameList].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String ? newValue) {
                                setState(() {
                                  programeName = newValue!;
                                });
      
                                fetchStageForProgram();
                              },
                            ),
                          ),
      
                          const SizedBox(height:20),

                          if(currentProgramPassword.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mật khẩu chương trình',style:TextStyle(fontSize:16,color:Color(0xFF1A4D2E),fontWeight: FontWeight.w800)),
                              const SizedBox(height:10),
                              Row(children: [
                                Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659596570/djz4bz5p8ppjnzghhrcy.png',height:25),
                                const SizedBox(width:10),
                                Text(currentProgramPassword,style:const TextStyle(fontSize:18,color:Colors.red,fontWeight: FontWeight.w700))
                              ],)
                            ],
                          ),
                          const SizedBox(height:20),
                          programeName != null 
                          ?
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Danh sách các chặng được tạo',style:TextStyle(fontSize:16,color:Color(0xFF1A4D2E),fontWeight: FontWeight.w800)),
                              programStage.isEmpty
                              ?
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(children: [
                                  Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1644332818/aa4_zfk64k.png',height:40),
                                  const SizedBox(width:5),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const[
                                      Text('Không có chặng được tạo',style:TextStyle(fontSize:14,color:Colors.red,fontWeight: FontWeight.w500)),
                                      Text('cho chương trình này',style:TextStyle(fontSize:14,color:Colors.red,fontWeight: FontWeight.w500))
                                    ],
                                  )
                                ],),
                              )
                              :
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical:10),
                                child: Column(
                                  children: [
                                    ...programStage.map((e) => Container(
                                      decoration: BoxDecoration(
                                        color:Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.23),
                                            spreadRadius:1,
                                            blurRadius:1,
                                            offset: const Offset(1,1), // changes position of shadow
                                          ),
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.23),
                                            spreadRadius:1,
                                            blurRadius:1,
                                            offset: const Offset(-1,-1), // changes position of shadow
                                          ),
                                        ],
                                      ),
                                      margin:const EdgeInsets.symmetric(vertical:5),
                                      padding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
                                      child: Row(
                                        children: [
                                          Image.network('https://res.cloudinary.com/dhrpdnd8m/image/upload/v1659098707/wznudxkak8yxhmw0frm2.png',height:35),
                                          const SizedBox(width:10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(e.name.length>25 ? e.name.substring(0,25)+'...' : e.name,style:const TextStyle(color: Colors.black,fontSize:16,fontWeight: FontWeight.w700,overflow:TextOverflow.ellipsis,)),
                                              Text(e.password,style:const TextStyle(color: Color.fromARGB(255, 73, 70, 70),fontSize:13,fontWeight: FontWeight.w500,overflow:TextOverflow.ellipsis,))
                                            ],
                                          )
                                        ]
                                      ),
                                    ))
                                  ]
                                ),
                              ),
                              const SizedBox(height:20),
                              const Text('Tạo chặng mới',style:TextStyle(fontSize:16,color:Color(0xFF1A4D2E),fontWeight: FontWeight.w800)),
                              const SizedBox(height:20),
                              // Tên chương trình
                              TextField(
                                controller: _nameController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  isDense:true,
                                  border : OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                    borderSide:const BorderSide(
                                      color: Colors.green,
                                      width: 1,
                                    )
                                  ),
                                  labelText: "Tên chặng",
                                )
                              ),
                              const SizedBox(height:24),
                              /*RawKeyboardListener(
                                focusNode: myFocusNode,
                                onKey: (event) {
                                  if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                                    setState((){
                                      description = description + "/n/";
                                    });
                                  }
                                },
                                child: */TextField(
                                  maxLines: 5,
                                  controller: _descriptionController,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.none,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.green, width: 1)
                                    ),
                                    labelText: "Miêu tả cho chặng",
                                  ),
                                ),
                              //),
                              const SizedBox(height: 24),
                              // Mật khẩu chương trình
                              TextField(
                                controller: _passwordController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  isDense:true,
                                  border : OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                    borderSide:const BorderSide(
                                      color: Colors.green,
                                      width: 1,
                                    )
                                  ),
                                  labelText: "Mật khẩu của chặng",
                                )
                              ),
                              const SizedBox(height:24),
                              
                              destinationUrl.isNotEmpty
                              ?
                              Container(
                                height: 300,
                                width: double.infinity,
                                margin:const EdgeInsets.only(bottom: 20),
                                child: WebView(
                                  initialUrl: destinationUrl,
                                  key: UniqueKey(),
                                  javascriptMode: JavascriptMode.unrestricted,
                                  onWebViewCreated: (WebViewController webViewController) {
                                    webViewController.loadUrl(destinationUrl);
                                  },
                                )
                              )
                              :
                              const SizedBox(height:0),
                              Container(
                                padding:const EdgeInsets.symmetric(horizontal:10,vertical:0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:Border.all(
                                    width:1,
                                    color:Colors.grey,
                                  ),
                                  color: Colors.white,  
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _destinationController,
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                          isDense:true,
                                          border : InputBorder.none,
                                          labelText: "Nhập địa điểm của chặng",
                                        )
                                      ),
                                    ),
                                    const SizedBox(width:10),
                                    ElevatedButton(
                                      onPressed:(){
                                        handleAddDestination();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.green,
                                        textStyle: const TextStyle(
                                          fontSize:14,
                                        )
                                      ),
                                      child: const Text('Kiểm tra'),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height:24),
                              SizedBox(
                                width: MediaQuery.of(context).size.width*1,
                                child: ElevatedButton(
                                  onPressed: () => handleAddNewStage(),
                                  style: ElevatedButton.styleFrom(
                                    primary: isLoading ? const Color.fromARGB(255, 44, 103, 46) :Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal:10, vertical:15),
                                    textStyle: const TextStyle(
                                      fontSize:17,
                                    )
                                  ),
                                  child:isLoading ?
                                   const Text('Đang tạo...', style: TextStyle(color:Colors.white,fontWeight: FontWeight.w600))
                                    : 
                                   const Text('Tạo chặng mới', style: TextStyle(color:Colors.white,fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          )
                          :
                          const SizedBox()
                        ],
                      )
                    )
                  ],
                )
              )
            
            ],
          ),
        ),
      ),
      
    );
  }
}
