import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import '../main.dart';
import '../db_helper.dart';

class AddHabit extends StatefulWidget {
  final Map<String, dynamic>? existingHabit;
  AddHabit({this.existingHabit});

  @override
  _AddHabitState createState() => _AddHabitState();
}

class _AddHabitState extends State<AddHabit> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _habitName = TextEditingController();
  final TextEditingController _description = TextEditingController();
  String selectedCategory = 'Study';
  String frequency = 'Everyday';
  Map<String, bool> days = {
    'Mon': false,
    'Tue': false,
    'Wed': false,
    'Thu': false,
    'Fri': false,
    'Sat': false,
    'Sun': false,
  };
  int? selectedDayOfMonth;

  @override
  void initState() {
    super.initState();
    if (widget.existingHabit != null) {
      _habitName.text = widget.existingHabit!['name'];
      _description.text = widget.existingHabit!['description'] ?? '';
      selectedCategory = widget.existingHabit!['category'] ?? 'Study';
      frequency = widget.existingHabit!['frequency'] ?? 'Everyday';
      if (frequency == 'Days' &&
          widget.existingHabit!['selectedDays'] != null) {
        List<String> selected = widget.existingHabit!['selectedDays'].split(
          ',',
        );
        days.forEach((key, _) {
          days[key] = selected.contains(key);
        });
      }
      if (frequency == 'Date' && widget.existingHabit!['dayOfMonth'] != null) {
        selectedDayOfMonth = widget.existingHabit!['dayOfMonth'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = const Color.fromARGB(255, 206, 206, 193);
    return Scaffold(
      appBar: myAppBar(
        widget.existingHabit != null ? 'Edit Habit' : 'Add Habit',
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                colorFilter: ColorFilter.mode(
                  const Color.fromARGB(255, 129, 129, 109).withOpacity(0.48),
                  BlendMode.dstATop,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Card(
                color: const Color.fromARGB(255, 2, 11, 63).withOpacity(0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habit Name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 5),
                      TextFormField(
                        controller: _habitName,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Please enter name',
                          hintStyle: TextStyle(
                            color: textColor.withOpacity(0.6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Please enter a habit name"
                            : null,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 5),
                      TextFormField(
                        controller: _description,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter description (optional)',
                          hintStyle: TextStyle(
                            color: textColor.withOpacity(0.6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: textColor),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Category: ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              style: TextStyle(color: textColor, fontSize: 16),
                              dropdownColor: const Color.fromARGB(
                                255,
                                2,
                                11,
                                63,
                              ),
                              isExpanded: true,
                              items:
                                  [
                                        'Study',
                                        'Health',
                                        'Self-Care',
                                        'Finance',
                                        'Social',
                                        'Hobby',
                                        'Household',
                                        'Other',
                                      ]
                                      .map(
                                        (cat) => DropdownMenuItem(
                                          value: cat,
                                          child: Text(
                                            cat,
                                            style: TextStyle(color: textColor),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedCategory = val!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Frequency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      RadioListTile(
                        title: Text(
                          'Everyday',
                          style: TextStyle(color: textColor),
                        ),
                        value: 'Everyday',
                        groupValue: frequency,
                        onChanged: (val) => setState(() => frequency = val!),
                        activeColor: textColor,
                      ),
                      RadioListTile(
                        title: Text(
                          'Selected Days',
                          style: TextStyle(color: textColor),
                        ),
                        value: 'Days',
                        groupValue: frequency,
                        onChanged: (val) => setState(() => frequency = val!),
                        activeColor: textColor,
                      ),
                      RadioListTile(
                        title: Text(
                          'Specific Date',
                          style: TextStyle(color: textColor),
                        ),
                        value: 'Date',
                        groupValue: frequency,
                        onChanged: (val) => setState(() => frequency = val!),
                        activeColor: textColor,
                      ),
                      if (frequency == 'Days')
                        Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: days.keys.map((day) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(day, style: TextStyle(color: textColor)),
                                  Checkbox(
                                    value: days[day],
                                    onChanged: (val) {
                                      setState(() {
                                        days[day] = val!;
                                      });
                                    },
                                    checkColor: Colors.black,
                                    activeColor: textColor,
                                    side: BorderSide(
                                      color: textColor,
                                      width: 2,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      if (frequency == 'Date')
                        Column(
                          children: [
                            Text(
                              'Select day of month',
                              style: TextStyle(color: textColor),
                            ),
                            SizedBox(height: 10),
                            NumberPicker(
                              value: selectedDayOfMonth ?? 1,
                              minValue: 1,
                              maxValue: 31,
                              onChanged: (val) {
                                setState(() {
                                  selectedDayOfMonth = val;
                                });
                              },
                              textStyle: TextStyle(
                                color: textColor.withOpacity(0.5),
                              ),
                              selectedTextStyle: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 25),
                      Center(
                        child: ElevatedButton(
                          child: Text('Save Habit'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              String selectedDaysStr = '';
                              int? dayOfMonth;
                              if (frequency == 'Days') {
                                selectedDaysStr = days.entries
                                    .where((e) => e.value)
                                    .map((e) => e.key)
                                    .join(',');
                              }
                              if (frequency == 'Date') {
                                dayOfMonth = selectedDayOfMonth;
                              }
                              Map<String, dynamic> habitData = {
                                'name': _habitName.text.trim(),
                                'description': _description.text.trim(),
                                'category': selectedCategory,
                                'frequency': frequency,
                                'selectedDays': selectedDaysStr,
                                'dayOfMonth': dayOfMonth,
                              };
                              int habitId;
                              if (widget.existingHabit != null) {
                                habitId = widget.existingHabit!['id'];
                                await DBHelper().updateHabit(
                                  habitId,
                                  habitData,
                                );
                              } else {
                                habitId = await DBHelper().insertHabit(
                                  habitData,
                                );
                              }
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              206,
                              206,
                              193,
                            ),
                            foregroundColor: const Color.fromARGB(
                              255,
                              2,
                              11,
                              63,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
