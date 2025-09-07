import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notesapp/components/mynavbar.dart';
import 'package:notesapp/components/mytasks.dart';
import 'package:notesapp/management/database.dart';
import 'package:notesapp/models/task.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({
    super.key,
    required this.email,
    this.initialFilter = "All",
  });

  //email to passed accross page
  //pour bien display les info corresponding

  final String email;

  //filters used to go from "status listTile(Dashboard) -> Filtered Page"
  final String initialFilter;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
//---Generating database instance

  final DatabaseManager _dbManager = DatabaseManager();
//---Selection of the filter depending on its status "done", "in progress"
//and etc...

  late String selectedFilter;

//List of tasks to display

  List<Task> tasks = [];

//initialising the state

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    _loadTasks();
  }

//loading the tasks stored in the database
//by making use of the getTasksForUser function
//that gets a specific task saved
//dans chaque user en particulier

  Future<void> _loadTasks() async {
    final fetchedTasks =
        await _dbManager.getTasksForUser(widget.email); // retourne List<Task>
    setState(() {
      tasks = fetchedTasks;
    });
  }

  // Create or edit task dialog that only has two statuses at first
  //mais on rajoute le done after quand on sera entrain
  //de edit the task

  void _showCreateTaskDialog({Task? task}) {
    final titleController = TextEditingController(text: task?.title ?? "");
    final subtitleController =
        TextEditingController(text: task?.subtitle ?? "");
    String status = task?.status ?? "To do";
    DateTime? selectedDate = task?.date;

//getting a task sous for the liste ou d'un item
//si un item task n'est pas null on le rajoute on the tasks list

    final Set<String> itemsSet = {"To do", "In progress"};
    if (task != null && !itemsSet.contains(task.status))
      itemsSet.add(task.status);
    final itemsList = itemsSet.toList();

//Show un alert dialog, qui est celui qui permet
//de create and insert its containt
////titre, sous-titre etc...

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
                      items: itemsList
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
                                : "${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}",
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

              //Quand le ListTile est selected les options
              //de Edit , Cancel les changes ou resauver pop up
              //si on efface , elle s'efface de la db, si on cancel you just pop
              //the context, donc on reviens sur la paga preceeding
              //si on click sur save c'est comme soit insert une nouvelle task
              //ou encore la update .
              //En gros on appelle the same alert dialog but if it's a new task
              //the button says "Add", if it's an update , meaning tasks is not null
              //the button devient save

              actions: [
                if (task != null)
                  TextButton(
                    onPressed: () async {
                      await _dbManager.deleteTask(task.id!);
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
                  child: const Text(
                    "Cancel",
                  ),
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
                          id: task.id!,
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
                  child: Text(task == null ? "Add" : "Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

//Displaying all tasks that have the selected filter "All"
  List<Task> get filteredTasks {
    if (selectedFilter == "All") return tasks;
    return tasks.where((t) => t.status == selectedFilter).toList();
  }

  // Menu to "Mark as Done", "Edit", "Delete"
  void _showTaskOptions(Task task) {
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
                  id: task.id!,
                  status: 'Done',
                  title: task.title,
                  subtitle: task.subtitle,
                  date: task.date,
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
                await _dbManager.deleteTask(task.id!);
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
          const SizedBox(
            height: 20,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                children: [
                  const Text('Filters'),
                  const SizedBox(
                    width: 6,
                  ),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildFilterButton("All"),
                      _buildFilterButton("To do"),
                      _buildFilterButton("In progress"),
                      _buildFilterButton("Done")
                    ],
                  ),
                ],
              ),
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
                          status: task.status,
                          title: task.title,
                          subject: task.subtitle,
                          date: task.date,
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
        backgroundColor: const Color(0xff050c20),
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      bottomNavigationBar: MyNavBar(currentIndex: 2, email: widget.email),
    );
  }

//Building the filters button that are on the top
//they're gesture detectors

  Widget _buildFilterButton(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff050c20) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xff050c20),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  //this returns a simple text that says no tasks yet
  //when there ism't any

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
