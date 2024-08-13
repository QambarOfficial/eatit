import 'package:flutter/material.dart';
import 'package:flutter_polls/flutter_polls.dart';

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
    String getTimeOfDay() {
      final now = DateTime.now(); // Get current time
      final hours = now.hour; // Get the current hour

      if (hours >= 6 && hours < 11) {
        return 'It\'s Breakfast Time';
      } else if (hours >= 11 && hours < 14) {
        return 'It\'s Lunch Time';
      } else if (hours >= 14 && hours < 18) {
        return 'It\'s Snack Time';
      } else if (hours >= 18 && hours < 22) {
        return 'It\'s Dinner Time';
      } else {
        return 'Night Cravings ?';
      }
    }

    final timeOfDay = getTimeOfDay(); // Determine the time of day

    // Sample poll data
    final pollOptions = votes.keys.map((food) {
      return PollOption(
        id: food, // Assuming food is a non-nullable string
        title: Text(food),
        votes: votes[food]!,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(timeOfDay), centerTitle: true),
      body: Column(
        children: [
          const Text('Select what everyone is going to eat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: votes.keys
                        .map((food) => RadioListTile<String>(
                              title: Text(food),
                              value: food,
                              groupValue: selectedFood,
                              onChanged: (value) {
                                setState(() {
                                  selectedFood = value ?? '';
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    print('Selected food: $selectedFood');
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "OR",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FlutterPolls(
              pollId: '1',
              onVoted: (PollOption pollOption, int newTotalVotes) async {
                print('Voted: ${pollOption.id}');
                setState(() {
                  // Update votes based on pollOption
                  votes[pollOption.id as String] = newTotalVotes;
                });
                // Return a Future<bool> to indicate success
                return true; // or false if you want to indicate failure
              },
              pollOptionsSplashColor: Colors.white,
              votedProgressColor: Colors.black.withOpacity(0.3),
              votedBackgroundColor: Colors.black.withOpacity(0.2),
              votesTextStyle: Theme.of(context).textTheme.titleMedium,
              votedPercentageTextStyle:
                  Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.black,
                      ),
              votedCheckmark: const Icon(
                Icons.check_circle,
                color: Colors.black,
                size: 18,
              ),
              pollTitle: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ask Family Members to Vote',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              pollOptions: pollOptions,
              metaWidget: const Row(
                children: [
                  SizedBox(width: 6),
                  Text(
                    '•',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '2 hours left',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                print('Vote button pressed: Sending requests to all members.');
                // Logic to send requests to all members goes here
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black, // Text color
              ),
              child: const Text('Vote'),
            ),
          ),
        ],
      ),
    );
  }
}
