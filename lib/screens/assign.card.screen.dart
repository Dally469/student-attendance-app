import 'package:attendance/api/auth.service.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/states/classroom.student/classroom_student_bloc.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignStudentCard extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  const AssignStudentCard({super.key, this.classroomId, this.classroom});

  @override
  State<AssignStudentCard> createState() => _AssignStudentCardState();
}

class _AssignStudentCardState extends State<AssignStudentCard> {
  ClassroomStudentBloc classroomStudentBloc =
      ClassroomStudentBloc(ClassroomStudentInitial(), AuthService());

  @override
  void initState() {
    super.initState();
    classroomStudentBloc = BlocProvider.of<ClassroomStudentBloc>(context);
    if (kDebugMode) {
      print("${widget.classroomId} - ${widget.classroom}");
    }
  }

  int studentLength = 0;

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();

    classroomStudentBloc.add(
        FetchClassroomStudentEvent(classroom: widget.classroom.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          toolbarHeight: 100, // Set the height of the AppBar
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "${widget.classroom.toString()}",
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                "Total students: $studentLength", // Replace 25 with the actual value
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
        body: Column(children: [
          BlocConsumer<ClassroomStudentBloc, ClassroomStudentState>(
            listener: (context, state) {
              // TODO: implement listener
              if (state is ClassroomStudentSuccess) {
                setState(() {
                  studentLength = state.studentModel.data!.length;
                });
              }
            },
            builder: (context, state) {
              if (state is ClassroomStudentLoading) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 70.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'Loading students',
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black),
                            ),
                            const SizedBox(height: 20),
                            const SpinKitDoubleBounce(
                              color: primaryColor,
                              size: 40,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is ClassroomStudentSuccess) {
                if (state.studentModel.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 70.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey, width: 2),
                            ),
                            padding: const EdgeInsets.all(
                                20), // adjust padding for icon size
                            child: const Icon(
                              Icons.inbox, // use any icon you prefer
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(
                              height: 16), // space between icon and text
                          Text(
                            'No Classroom found',
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Expanded(
                    child: ListView.builder(
                  itemCount: state.studentModel.data!.length,
                  itemBuilder: (context, index) {
                    final student = state.studentModel.data![index];
                    final isCardAssigned = student.cardAvailable !=
                        null; // Check if the card is assigned

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: whiteColor1,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 188, 188, 188)
                                .withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          backgroundImage: student.profileImage != null
                              ? NetworkImage(student
                                  .profileImage!) // Use the student's image
                              : null, // Placeholder if no image is available
                          child: student.profileImage == null
                              ? Icon(Icons.person, color: primaryColor)
                              : null,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${student.name}",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              'Code: ${student.code}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                        trailing: isCardAssigned
                            ? null
                            : TextButton(
                                onPressed: () {
                                  // Add your "Assign Card" logic here
                                  context.safeGoNamed(addCard, params: {
                                    'studentName': student.name.toString(),
                                    'studentId': student.id.toString(),
                                    'studentCode': student.code.toString(),
                                    'classroom': student.classroom.toString(),
                                  });
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Assign Card",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                        onTap: () {
                          // Add any logic for tapping on the list item
                          context.safeGoNamed(addCard, params: {
                            'studentName': student.name.toString(),
                            'studentId': student.id.toString(),
                            'studentCode': student.code.toString(),
                          });
                        },
                      ),
                    );
                  },
                ));
              }
              return const Text('');
            },
          ),
        ]),
        bottomSheet: Container(
          color: whiteColor,
          height: 40,
          child: Center(
            child: Text(
              "Powerd by Besoft & BePay ltd",
              style: GoogleFonts.poppins(fontSize: 12, color: blackColor),
            ),
          ),
        ),
      ),
    );
  }
}
