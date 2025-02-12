import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_soc/routes.dart';

class SecDashboardUsers extends StatefulWidget {
  const SecDashboardUsers({super.key});

  @override
  State<SecDashboardUsers> createState() => _SecDashboardUsersState();
}

class _SecDashboardUsersState extends State<SecDashboardUsers> {
  late Map<String, dynamic> args;
  late QuerySnapshot result;

  Future fetchAllUsers() async {
    result = await FirebaseFirestore.instance
        .collection('users')
        .where('buildingId', isEqualTo: args['userDetails']['buildingId'])
        .get();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Color(0xFF1A1A2E),
          title: Text(
            'For ${args['buildingDetails']['buildingName']}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
          ),
          child: FutureBuilder(
            future: fetchAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE94560),
                    strokeWidth: 3,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        "Something went wrong",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        "${snapshot.error}",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }
              if (snapshot.hasData) {
                List allUsers = snapshot.data!.docs;
                return UserTile(allUserData: allUsers);
              } else {
                return Center(
                  child: CircularProgressIndicator(color: Color(0xFFE94560)),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final List allUserData;
  const UserTile({super.key, required this.allUserData});

  void detailed_view(context, DocumentSnapshot user) async {
    await Navigator.pushNamed(context, MySocRoutes.secDashboardUserDetails,
        arguments: {'details': user});
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: allUserData.length,
      itemBuilder: (context, index) {
        final userData = allUserData[index].data();
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          elevation: 2,
          color: Colors.white.withOpacity(0.05),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => detailed_view(context, allUserData[index]),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFE94560).withOpacity(0.2),
                    child: Text(
                      '${userData['firstName'][0]}${userData['lastName'][0]}',
                      style: TextStyle(
                        color: Color(0xFFE94560),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${userData['firstName']} ${userData['lastName']}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: userData['isVerified']
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    userData['isVerified']
                                        ? Icons.verified_user
                                        : Icons.hourglass_empty,
                                    size: 16,
                                    color: userData['isVerified']
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    userData['isVerified']
                                        ? 'Verified'
                                        : 'Pending',
                                    style: TextStyle(
                                      color: userData['isVerified']
                                          ? Colors.green
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          userData['email'],
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.home_outlined,
                              size: 16,
                              color: Colors.white60,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Wing ${userData['wing']} - ${userData['flatNumber']}',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SecDashboardUserDetails extends StatefulWidget {
  const SecDashboardUserDetails({super.key});

  @override
  State<SecDashboardUserDetails> createState() =>
      _SecDashboardUserDetailsState();
}

class _SecDashboardUserDetailsState extends State<SecDashboardUserDetails> {
  bool isSwitched = false;
  TextEditingController remarks = TextEditingController();
  late Map args;
  bool isloading = true;
  late Map arg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      arg = ModalRoute.of(context)!.settings.arguments as Map;
      args = arg['details'].data();
      isSwitched = args['isVerified'];
      setState(() {
        isloading = false;
      });
    });
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Color(0xFFE94560),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isloading
        ? Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE94560)),
            ),
          )
        : SafeArea(
            child: Scaffold(
              appBar: AppBar(
                elevation: 0,
                title: Text(
                  'User Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Color(0xFF1A1A2E),
                iconTheme: IconThemeData(color: Colors.white),
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Personal Information',
                        [
                          _buildDetailRow("First Name", args['firstName']),
                          _buildDetailRow("Last Name", args['lastName']),
                          _buildDetailRow("Email", args['email']),
                          _buildDetailRow("Phone", args['phone']),
                          _buildDetailRow("Aadhaar", args['aadharNumber']),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildSection(
                        'Residence Details',
                        [
                          _buildDetailRow("Wing", args['wing']),
                          _buildDetailRow(
                              "Floor", args['floorNumber'].toString()),
                          _buildDetailRow("Flat", args['flatNumber']),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildSection(
                        'Vehicles',
                        args['vehicles'].map<Widget>((vehicle) {
                          return Card(
                            color: Colors.white.withOpacity(0.05),
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                vehicle['type'].toLowerCase() == 'car'
                                    ? Icons.directions_car
                                    : Icons.two_wheeler,
                                color: Color(0xFFE94560),
                              ),
                              title: Text(
                                vehicle['type'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                vehicle['number'],
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: remarks,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Remarks",
                          alignLabelWithHint: true,
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Color(0xFFE94560),
                              width: 2,
                            ),
                          ),
                          fillColor: Colors.white.withOpacity(0.05),
                          filled: true,
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 16),
                      Card(
                        color: Colors.white.withOpacity(0.05),
                        child: SwitchListTile(
                          title: Text(
                            'Approve User',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            isSwitched
                                ? 'User is verified'
                                : 'User is pending verification',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: isSwitched,
                          onChanged: (value) async {
                            setState(() => isSwitched = value);
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(arg['details'].id)
                                .update({
                              'isVerified': value,
                              'verifiedBy': value
                                  ? FirebaseAuth.instance.currentUser?.email
                                  : "",
                              'lastUpdated': FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'User approved successfully'
                                      : 'User verification revoked',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor:
                                    value ? Colors.green : Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: EdgeInsets.all(16),
                              ),
                            );

                            Future.delayed(Duration(seconds: 2), () {
                              Navigator.pop(context);
                            });
                          },
                          activeColor: Color(0xFFE94560),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
