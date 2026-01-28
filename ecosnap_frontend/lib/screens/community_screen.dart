import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> questions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/community/questions'));
      if (response.statusCode == 200) {
        setState(() {
          questions = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching questions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> postQuestion(String title, String content) async {
    // Dummy user data
    final body = {
      "user_id": "test_user_id",
      "user_name": "Eco User", 
      "title": title,
      "content": content,
      "category": "General",
      "city": "Mumbai"
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/community/questions'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        fetchQuestions();
      }
    } catch (e) {
      print("Error posting question: $e");
    }
  }

  void _showAddQuestionDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ask the Community"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Question Title"),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: "Details"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                postQuestion(titleController.text, contentController.text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Q&A"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: questions.length,
              itemBuilder: (ctx, index) {
                final q = questions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(q['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q['content']),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text("${q['upvotes']}"),
                            const SizedBox(width: 15),
                            Icon(Icons.comment, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text("${q['answer_count']} Answers"),
                          ],
                        )
                      ],
                    ),
                    trailing: Text(
                      "${q['category']} • ${q['city'] ?? 'All India'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        child: const Icon(Icons.add),
        tooltip: "Ask Question",
      ),
    );
  }
}
