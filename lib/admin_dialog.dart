import 'package:flutter/material.dart';

class AdminDialog extends StatefulWidget {
  final Map<String, Map<String, String>> weeklyMenu;
  final List<Map<String, String>> familyMembers;
  final Function(String, String, String) onMenuUpdate; // Updated callback
  final Function(List<Map<String, String>>) onFamilyUpdate; // New callback

  const AdminDialog({
    super.key,
    required this.weeklyMenu,
    required this.familyMembers,
    required this.onMenuUpdate,
    required this.onFamilyUpdate,
  });

  @override
  _AdminDialogState createState() => _AdminDialogState();
}

class _AdminDialogState extends State<AdminDialog> {
  late TextEditingController _nameController;
  late TextEditingController _favoriteFoodController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _favoriteFoodController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _favoriteFoodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Admin Dialog"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Weekly Menu:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.weeklyMenu.length,
                itemBuilder: (BuildContext context, int index) {
                  String day = widget.weeklyMenu.keys.elementAt(index);
                  return _buildFoodItem(
                    context,
                    day,
                    widget.weeklyMenu[day]!['lunch']!,
                    widget.weeklyMenu[day]!['dinner']!,
                    (String newLunch, String newDinner) {
                      widget.onMenuUpdate(day, newLunch, newDinner);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Family Members:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.familyMembers.length,
                itemBuilder: (BuildContext context, int index) {
                  String name = widget.familyMembers[index]["name"]!;
                  String favoriteFood =
                      widget.familyMembers[index]["favoriteFood"]!;
                  return _buildFamilyMemberItem(name, favoriteFood, index);
                },
              ),
            ),
            const SizedBox(height: 10),
            _buildAddFamilyMember(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, String day, String lunchItem,
      String dinnerItem, Function(String, String) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$day:",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text("Lunch: $lunchItem"),
        Text("Dinner: $dinnerItem"),
        const SizedBox(height: 10),
        ElevatedButton(
          child: const Text("Edit"),
          onPressed: () {
            _editDishes(context, day, lunchItem, dinnerItem, onUpdate);
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildFamilyMemberItem(String name, String favoriteFood, int index) {
    return ListTile(
      title: Text(name),
      subtitle: Text("Favorite Food: $favoriteFood"),
      leading: CircleAvatar(
        child: Text(name[0]),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          _deleteFamilyMember(index);
        },
      ),
    );
  }

  Widget _buildAddFamilyMember() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _favoriteFoodController,
            decoration: const InputDecoration(labelText: 'Favorite Food'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _addFamilyMember();
          },
        ),
      ],
    );
  }

  void _editDishes(BuildContext context, String day, String currentLunch,
      String currentDinner, Function(String, String) onUpdate) {
    String newLunch = currentLunch;
    String newDinner = currentDinner;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Dishes for $day"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Lunch'),
                  controller: TextEditingController(text: newLunch),
                  onChanged: (value) {
                    newLunch = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Dinner'),
                  controller: TextEditingController(text: newDinner),
                  onChanged: (value) {
                    newDinner = value;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Update"),
              onPressed: () {
                onUpdate(newLunch, newDinner);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        );
      },
    );
  }

  void _addFamilyMember() {
    String name = _nameController.text;
    String favoriteFood = _favoriteFoodController.text;
    if (name.isNotEmpty && favoriteFood.isNotEmpty) {
      setState(() {
        widget.familyMembers.add({
          "name": name,
          "favoriteFood": favoriteFood,
        });
      });
      widget.onFamilyUpdate(widget.familyMembers);
      _nameController.clear();
      _favoriteFoodController.clear();
    }
  }

  void _deleteFamilyMember(int index) {
    setState(() {
      widget.familyMembers.removeAt(index);
    });
    widget.onFamilyUpdate(widget.familyMembers);
  }
}
