import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/admin_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDosenDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'password123'); // prefill default
    final nimController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurface(context),
          title: const Text('Tambah Akun Dosen', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nimController,
                    decoration: const InputDecoration(labelText: 'NIM / NIP', hintText: 'Min. 7 digit angka'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'NIM/NIP tidak boleh kosong';
                      if (!RegExp(r'^\d+$').hasMatch(val)) return 'NIM/NIP harus berupa angka';
                      if (val.trim().length < 7) return 'NIM/NIP minimal 7 digit';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Dosen'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email tidak boleh kosong';
                      if (!val.contains('@')) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Awal',
                      hintText: 'Misal: password123',
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Password tidak boleh kosong' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Batal', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final newDosen = UserModel(
                  id: 'u_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  role: UserRole.dosen,
                  password: passwordController.text,
                  nim: nimController.text.trim(),
                );

                await Provider.of<AdminProvider>(context, listen: false).saveDosen(newDosen);
                if (context.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final nimController = TextEditingController(text: user.nim);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurface(context),
          title: Text('Edit ${user.role == UserRole.dosen ? "Dosen" : "Mahasiswa"}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nimController,
                    decoration: const InputDecoration(labelText: 'NIM / NIP', hintText: 'Min. 7 digit angka'),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'NIM/NIP tidak boleh kosong';
                      if (!RegExp(r'^\d+$').hasMatch(val)) return 'NIM/NIP harus berupa angka';
                      if (val.trim().length < 7) return 'NIM/NIP minimal 7 digit';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email tidak boleh kosong';
                      if (!val.contains('@')) return 'Email tidak valid';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Batal', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final updatedUser = user.copyWith(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  nim: nimController.text.trim(),
                );

                final adminProv = Provider.of<AdminProvider>(context, listen: false);
                if (user.role == UserRole.dosen) {
                  await adminProv.saveDosen(updatedUser);
                } else {
                  await adminProv.saveMahasiswa(updatedUser);
                }
                
                if (context.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final dosenList = provider.dosenList;
    final mahasiswaList = provider.mahasiswaList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.getTextSecondary(context),
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Dosen'),
            Tab(text: 'Mahasiswa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dosen management tab
          _buildUserTab(
            context,
            userList: dosenList,
            emptyMessage: 'Belum ada akun Dosen terdaftar.',
            onAddPressed: () => _showAddDosenDialog(context),
            addButtonLabel: 'Tambah Dosen',
          ),
          // Mahasiswa management tab
          _buildUserTab(
            context,
            userList: mahasiswaList,
            emptyMessage: 'Belum ada akun Mahasiswa terdaftar.',
            // Mahasiswa registers themselves
            addButtonLabel: null,
            onAddPressed: null,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTab(
    BuildContext context, {
    required List<UserModel> userList,
    required String emptyMessage,
    String? addButtonLabel,
    VoidCallback? onAddPressed,
  }) {
    final provider = Provider.of<AdminProvider>(context, listen: false);

    return Column(
      children: [
        if (addButtonLabel != null && onAddPressed != null) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add),
                label: Text(addButtonLabel),
              ),
            ),
          ),
        ],
        Expanded(
          child: userList.isEmpty
              ? Center(
                  child: Text(
                    emptyMessage,
                    style: TextStyle(color: AppTheme.getTextSecondary(context)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final user = userList[index];
                    return Card(
                      color: AppTheme.getSurface(context),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary)),
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${user.email} • NIM/NIP: ${user.nim ?? "-"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.accent),
                              onPressed: () => _showEditUserDialog(context, user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppTheme.getSurface(context),
                                    title: const Text('Hapus Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
                                    content: Text('Apakah Anda yakin ingin menghapus akun ${user.name}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text('Batal', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                        onPressed: () async {
                                          if (user.role == UserRole.dosen) {
                                            await provider.deleteDosen(user.id);
                                          } else {
                                            await provider.deleteMahasiswa(user.id);
                                          }
                                          if (context.mounted) Navigator.pop(ctx);
                                        },
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
