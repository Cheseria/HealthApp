import 'package:flutter/material.dart';

class RoleDropdown extends StatefulWidget {
  final String? selectedRole;
  final ValueChanged<String?> onRoleChanged;

  const RoleDropdown({Key? key, this.selectedRole, required this.onRoleChanged})
      : super(key: key);

  @override
  State<RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<RoleDropdown> {
  final List<String> roles = ['Doctor', 'User'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500, // Set your desired width here
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
            child: Text(
              'Select Role',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          DropdownMenu<String>(
            initialSelection: widget.selectedRole,
            onSelected: (String? value) {
              // This is called when the user selects an item.
              widget.onRoleChanged(value);
            },
            dropdownMenuEntries:
                roles.map<DropdownMenuEntry<String>>((String role) {
              return DropdownMenuEntry<String>(
                value: role.toLowerCase(),
                label: role,
              );
            }).toList(),
            width: 500,
          ),
        ],
      ),
    );
  }
}
