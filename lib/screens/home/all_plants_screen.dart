
// NOTE:
// This is a starter replacement for all_plants_screen.dart.
// Paste your existing PlantCard UI inside the marked ListView.builder section
// if you want to preserve every visual detail.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../detail/plant_detail_screen.dart';

class AllPlantsScreen extends StatefulWidget {
  final bool? isFree;
  final String title;

  const AllPlantsScreen({
    super.key,
    this.isFree,
    required this.title,
  });

  @override
  State<AllPlantsScreen> createState() => _AllPlantsScreenState();
}

class _AllPlantsScreenState extends State<AllPlantsScreen> {
  String searchText = "";
  String selectedCategory = "All";

  final List<String> categories = const [
    "All","Indoor","Outdoor","Flower","Fruit",
    "Vegetable","Medicinal","Succulent","Herb","Tree","Climber"
  ];

  IconData _getCategoryIcon(String c){
    switch(c){
      case "Indoor": return Icons.weekend;
      case "Outdoor": return Icons.wb_sunny;
      case "Flower": return Icons.local_florist;
      case "Fruit": return Icons.apple;
      case "Vegetable": return Icons.eco;
      case "Medicinal": return Icons.medication;
      case "Succulent": return Icons.spa;
      case "Herb": return Icons.grass;
      case "Tree": return Icons.park;
      case "Climber": return Icons.forest;
      default: return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
      .collection("plants")
      .where("status", isEqualTo: "Available");

    if(widget.isFree!=null){
      query=query.where("isFree",isEqualTo: widget.isFree);
    }

    query=query.orderBy("createdAt",descending:true);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children:[
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  child: Wrap(
    spacing: 10,
    runSpacing: 10,
    alignment: WrapAlignment.center,
    children: categories.map((category) {

      final selected = selectedCategory == category;

      return FilterChip(
        avatar: Icon(
          _getCategoryIcon(category),
          size: 18,
          color: selected
              ? Colors.white
              : Colors.green,
        ),

        label: Text(category),

        selected: selected,

        selectedColor: Colors.green,

        backgroundColor: Colors.white,

        elevation: selected ? 5 : 1,

        shadowColor: Colors.green,

        checkmarkColor: Colors.white,

        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : Colors.black,
          fontWeight: FontWeight.bold,
        ),

        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(25),
        ),

        onSelected: (_) {
          setState(() {
            selectedCategory = category;
          });
        },
      );

    }).toList(),
  ),
),
          const SizedBox(height:8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder:(context,snapshot){
                if(snapshot.connectionState==ConnectionState.waiting){
                  return const Center(child:CircularProgressIndicator());
                }
                if(snapshot.hasError){
                  return Center(child:Text(snapshot.error.toString()));
                }

                var plants=snapshot.data?.docs??[];

                plants=plants.where((d){
                  final p=d.data() as Map<String,dynamic>;
                  final name=(p["name"]??"").toString().toLowerCase();
                  final sci=(p["scientificName"]??"").toString().toLowerCase();
                  final cat=(p["category"]??"").toString().toLowerCase();
                  final sub=(p["subCategory"]??"").toString().toLowerCase();

                  final okSearch=searchText.isEmpty||
                      name.contains(searchText)||sci.contains(searchText);

                  final okCat=selectedCategory=="All"||
                      cat.contains(selectedCategory.toLowerCase())||
                      sub.contains(selectedCategory.toLowerCase());

                  return okSearch&&okCat;
                }).toList();

                if(plants.isEmpty){
                  return const Center(child:Text("No plants found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: plants.length,
                  itemBuilder:(context,index){
                    final doc=plants[index];
                    final plant=doc.data() as Map<String,dynamic>;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_florist,color:Colors.green),
                        title: Text(plant["name"]??""),
                        subtitle: Text(plant["category"]??""),
                        trailing: Text(
                          plant["isFree"]==true
                            ?"FREE"
                            :"₹ ${plant["price"]??0}"
                        ),
                        onTap:(){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:(_)=>PlantDetailScreen(
                                documentId: doc.id,
                                plant: plant,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
