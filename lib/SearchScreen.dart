import 'package:flutter/material.dart';



class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String selectedFood = '';
  Map<String, int> votes = {'Pizza': 0, 'Burger': 0, 'Pasta': 0};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Poll')),
      body: Column(
        children: votes.keys.map((food) => RadioListTile<String>(
              title: Text(food),
              value: food,
              groupValue: selectedFood,
              onChanged: (value) {
                setState(() {
                  selectedFood = value ?? ''; // Fix null safety issue
                });
              },
            )).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedFood.isNotEmpty) {
            setState(() {
              votes[selectedFood] = votes[selectedFood]! + 1;
            });
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
