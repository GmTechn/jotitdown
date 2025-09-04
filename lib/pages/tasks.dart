import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/components/mynavbar.dart';
import 'package:notesapp/components/mytasks.dart';
import 'package:notesapp/management/database.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.email});
  final String email;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final DatabaseManager _dbManager = DatabaseManager();

  List<Map<String, dynamic>> tasks = [];
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final rows = await _dbManager.getTasksForUser(widget.email);
    setState(() {
      tasks = rows;
    });
  }

  //Create Task for the first time with only two statuses

  void _showCreateTaskDialog({Map<String, dynamic>? task}) {
    final titleController = TextEditingController(text: task?["title"] ?? "");
    final subtitleController =
        TextEditingController(text: task?["subtitle"] ?? "");
    String status = task?["status"] ?? "To do";
    DateTime? selectedDate = task != null ? DateTime.parse(task["date"]) : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(task == null ? "Create Task" : "Edit Task"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: status,
                      items: ["To do", "In progress"]
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (val) => setStateDialog(() => status = val!),
                      decoration: const InputDecoration(labelText: "Status"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(labelText: "Subtitle"),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? "No date chosen"
                                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setStateDialog(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: const Text(
                            "Select Date",
                            style: TextStyle(color: Color(0xff050c20)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                if (task != null)
                  TextButton(
                    onPressed: () async {
                      await _dbManager.deleteTask(task["id"]);
                      await _loadTasks();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        subtitleController.text.isNotEmpty &&
                        selectedDate != null) {
                      if (task == null) {
                        await _dbManager.insertTask(
                          userEmail: widget.email,
                          status: status,
                          title: titleController.text,
                          subtitle: subtitleController.text,
                          date: selectedDate!,
                        );
                      } else {
                        await _dbManager.updateTask(
                          id: task["id"],
                          status: status,
                          title: titleController.text,
                          subtitle: subtitleController.text,
                          date: selectedDate!,
                        );
                      }
                      await _loadTasks();
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(task == null ? "Add" : "Save",
                      style: const TextStyle(color: Colors.green)),
                ),
              ],
            );
          },
        );
      },
    );
  }

//Filtering tasks selection

  List<Map<String, dynamic>> get filteredTasks {
    if (selectedFilter == "All") return tasks;
    return tasks.where((t) => t["status"] == selectedFilter).toList();
  }

//Menu to "Edit", "Delete", "Update" tasks
//ListTiles to display those options

  void _showTaskOptions(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text("Mark as Done"),
              onTap: () async {
                await _dbManager.updateTask(
                  id: task["id"],
                  status: "Done",
                  title: task["title"],
                  subtitle: task["subtitle"],
                  date: DateTime.parse(task["date"]),
                );
                Navigator.of(context).pop();
                await _loadTasks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Edit Task"),
              onTap: () {
                Navigator.of(context).pop();
                _showCreateTaskDialog(task: task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Task"),
              onTap: () async {
                await _dbManager.deleteTask(task["id"]);
                Navigator.of(context).pop();
                await _loadTasks();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("M Y  T A S K S"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Row (reduced)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Filters'),
                Wrap(
                  spacing: 10,
                  children: [
                    _buildFilterButton("All"),
                    _buildFilterButton("To do"),
                    _buildFilterButton("In progress"),
                    _buildFilterButton("Done")
                  ],
                ),
                // const Icon(Icons.filter_list, color: Colors.black54),
              ],
            ),
          ),

          Expanded(
            child: filteredTasks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return GestureDetector(
                        onTap: () => _showTaskOptions(task),
                        child: TaskCard(
                          status: task["status"],
                          title: task["title"],
                          subject: task["subtitle"],
                          date: DateTime.parse(task["date"]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add a new task',
        onPressed: () => _showCreateTaskDialog(),
        backgroundColor: Colors.black,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      bottomNavigationBar: MyNavBar(currentIndex: 2, email: widget.email),
    );
  }

//Building buttons to filter the tasks
//Showing "Done", "All", "In progress", "To do"

  Widget _buildFilterButton(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

//Displaying a text when there is not task

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "No tasks yet",
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.normal, color: Colors.grey),
      ),
    );
  }
}
