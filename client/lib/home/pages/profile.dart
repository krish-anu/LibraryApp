import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libraryapp/core/providers/theme_provider.dart';
import 'package:libraryapp/core/theme/app_pallete.dart';

class Profile extends ConsumerWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkProvider);
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Profile", style: TextStyle(fontSize: 36))),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  decoration: BoxDecoration(
                    color: Pallete.primaryLight,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),

                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(
                              "https://imgs.search.brave.com/3B_SYXXUKA9Ou_fT79_C_16EtIRigAAFd0itd7KO3oM/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9zdGF0/aWMudmVjdGVlenku/Y29tL3N5c3RlbS9y/ZXNvdXJjZXMvdGh1/bWJuYWlscy8wMjIv/OTU1LzI5Ni9zbWFs/bC9wb3J0cmFpdC1v/Zi1idXNpbmVzc3Bl/cnNvbi1hbmQtdGhl/LWdlbmVyYXRpb24t/cGVyc29uYWxpdGll/cy1vZi1uZXctZXhl/Y3V0aXZlcy13aXRo/LWdvb2QtaWRlYXMt/cGVyc29uYWxpdHkt/YW5kLXZpc2lvbi1w/aG90by5qcGc",
                            ),
                          ),
                        ),
                      ),

                      Text("Anusan", style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.email, color: Pallete.iconSuccess),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Email", style: TextStyle(fontSize: 20)),
                          Text("krishnaanu200302@gmail.com"),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () {},
                      child: Row(
                        children: [
                          Text("My Activity"),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.arrow_forward),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Change password",
                          style: TextStyle(
                            color: const Color.fromARGB(255, 16, 16, 16),
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "Current password",
                      ),
                    ),
                    SizedBox(height: 18),
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "New password",
                      ),
                    ),
                    SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(),
                        OutlinedButton(onPressed: () {}, child: Text("Save")),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 15),

                ListTile(
                  leading: Icon(Icons.dark_mode),
                  title: Text("Dark Mode"),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      ref.read(isDarkProvider.notifier).state = value;
                    },
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () {},
                      child: Row(children: [Text("Support")]),
                    ),
                  ],
                ),

                SizedBox(height: 15),
                FractionallySizedBox(
                  widthFactor: 0.9,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Pallete.logoutBtn,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      "Logout",
                      style: TextStyle(fontSize: 24, color: Pallete.error),
                    ),
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
