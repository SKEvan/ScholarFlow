import 'package:flutter/material.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final int _activeTab = 2; // Network tab active

  // Track pending states for suggestions
  final Map<int, bool> _pendingConnections = {};

  final List<Map<String, String>> _suggestions = [
    {
      'name': 'Dr. Elena Rostova',
      'role': 'Lead AI Ethicist, MIT',
      'tag': 'STEM',
      'mutuals': '14 mutuals',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAE8QyRB_7ilOBo4w4XjbtHLz1FtMDgbzSBrikzchsXk7WJ8z8a27kTFo3XJ3UaDPYjEMBGFkU55LWahaCivP9_LBcDFK3XNB9TcffTDtDL6DDAEoAKGPCv9fjcRMW5_THy2N7kEt31yuVFkvIP2XsWVIVT6VyX4irHyvXnSNv9DxIIikEbYkINgZ2RkpHab03QLrW7gajL3OYrrjKBj_C6cQ4qy_P_6sx3jPUVHvQtYj6Lh_zXq2WvGLdmRpt3zWxAmq8QNvO9zLc',
    },
    {
      'name': 'Prof. Julian Vane',
      'role': 'Director, Oxford Lab',
      'tag': 'SOCIAL SCIENCE',
      'mutuals': '8 mutuals',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDM8aIowItoRJNGZqQnt41eMBKVc0Zg1BwQXy-ze1FW9kXdXiz2f7sNbTa--K9erwDSsQzTFNN9fq6mCpyIy1_zGQjyXaqvU_dAn2jh83gzaoFgtAefLsarMrbzLNBqoZa13fUntB4gfNqBcqxNXE7XO_JSi9N8ybPJqjD3pE6bpyB8mbIIzw3HKBC_yauKsosqs_KrIUPPvbqp78IbCai3VlCStSj9h7K3hZlrXjoxPik-FHnwpxfWs7f01R7RHgcomRUuJ_hBxSM',
    },
    {
      'name': 'Sarah Jenkins',
      'role': 'PhD Candidate, Stanford',
      'tag': 'BIO-TECH',
      'mutuals': '22 mutuals',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAZsmH02TNgaDJw7KPz3cuhKYBWVYPdJjzZeEFqRzQkL5EpJeJyqOTl7zC-mH4HsizUd6TVkivOol-tmZVJN9lm9nGtvljaLfcDq2DUX3A-WGJv1MBF1TWfrWHkNbkvAVn4wVuUjIpOL-uzGxiVvzIBfQOonKoy75r7QnCXbGIZIxNYrhLTYEh69QCxY-M3H2NW_lDrmgxOECGzqRKkgUX2SI1HFKkrmhsd00ZFNcvKfR3jmVtu72ts1F76ebfy0ddSYXH0Bwu9LQs',
    },
  ];

  final List<Map<String, String>> _collaborators = [
    {
      'name': 'Marcus Thorne',
      'role': 'Data Scientist at Stanford',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCW4j_pfRwTazUQ1TSWYgk8C3V1wjmstnoQUWFr4DizYiGZ5vzUwNTjR43KGNzUyzKFojUMZwayBsySlEF5-bfgW37cVzzWTBVKXt5gDddR_H_FInt2lrFXoO4Ggg-tEjlZhjbovLagj7Sd7Rcb96ql4fYVxTJGc-5MnJBZmyhc9wuYBypwUJSfgUQeX_fmxxnHvzcTEARSACj4O1UbrLPy8Fi96Mwv0cff-6-Ku9KYXh9aSCFAw35qGDyEgCErCuXT6xXlzWDadYI',
    },
    {
      'name': 'Dr. Aisha Khan',
      'role': 'Senior Fellow, CERN',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDJ1vvsmh9wjU51Y_shaEJup1AvQ237WI-TMyIhlXaN3OeyIhAi4NA1NXqdV0ZNKOnHHVQMP1V9ndpqIXEm4FWgayLPwGcuKemRsmrUTBg4cc8Rw1elOlyrqDOsmxZWoNz_XBfdiJ2g5Aptxtgh5ir30ekENMYNJkJMDezPSuSjpG3pPyQVIuJLOsGf5aL1lOmka8U-eaOMw8snXIKeQuXh7kll15FDVcxzrlXefo9nnLYxQORKK4uLSbsJHN27RrQhaWOV26lRSU4',
    },
    {
      'name': "Liam O'Connor",
      'role': 'Quant Researcher, Citadel',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAHywDAfRghwxZuCgE0cPJ92kjRWqRdIqgle9OZebpRZZbgIF3s1tj_P26ygerexm4iraoLR2OKc5siaVr8IN0hNAcY2ipfhOiHosi2XAJjKaH9sQReoDkOnf9sC32lk04ZdL259UUeeCXnnv0UBR9--Eo1UWYwdvw_Kjk928XbOwS0otY3-0RWC_cD-rN9t0d17CJm7ooFvh-KQeRE0HMYcr_jyY7laByieYEeykoYMKhDjvP9b-KUCQ_WJ46NiR7iILXHfF9YFF8',
    },
    {
      'name': 'Prof. Maria Garcia',
      'role': 'Humanities Chair, Yale',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBevF_jAMmkBZweQtPSDiPUdc492xTdQcnCx5wEM05xyQuQwankiZZUYTG3NCpgdvgndfp5-iOLqqzRFfkj3zPtinws0Qbe2kMOa2i3vkkC6GYhCxZy1QcpBq38NPPoT7DK5ZqnaG5Ut2Tb_2CSYxJTi7g5kkC2SD-tp4LsETxr2bsdvGd0xk9dEYzIdgVLVTB33aNNB-voza4tOtzUyb_QvIq-HllIDDsl9UeX1RPASxTHNnMcfFuXCrKo97cwIesnINJtxrs7smk',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'ScholarFlow Network',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0, left: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCDjXO6XdfVP3zb59HMwG0pquQ-J-rFjlEydjXls8se839eUpxOxo3bL0RJr9L4LQZzo8IAc7DYmcKWmLraT6Kzmdl6Tnxl0q3tYfF6mkOd4g5ybsZpDEqY6jg2IfzXU6-Uw4NHqO5pRCgmLdcdyPGF609Un814FBXuLAZZ1nsXUGHNfK33eUMUBHI8dWJbXkhA36U0-HypTZjjlzHt69Df6Z7CbxMx1nMdnciVKL3UpcpKGzYxBxWDEDGhhAHE2Iyz8FJW5u77tWE',
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search researchers or institutions...',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.secondary, width: 1.0),
                  ),
                ),
              ),
            ),

            // Suggested Connections
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Suggested',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'VIEW ALL',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 270,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      final isPending = _pendingConnections[index] ?? false;

                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12.0, bottom: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(item['avatar']!),
                              child: ClipOval(
                                child: Image.network(
                                  item['avatar']!,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item['tag'] == 'STEM'
                                    ? theme.colorScheme.secondary.withOpacity(0.1)
                                    : theme.colorScheme.secondaryContainer.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['tag']!,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['name']!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['role']!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group, size: 14, color: theme.colorScheme.outline),
                                const SizedBox(width: 4),
                                Text(
                                  item['mutuals']!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isPending
                                    ? null
                                    : () {
                                        setState(() {
                                          _pendingConnections[index] = true;
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPending
                                      ? theme.colorScheme.outlineVariant
                                      : theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text(
                                  isPending ? 'PENDING' : 'CONNECT',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // My Collaborators
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Collaborators',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '128 TOTAL',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _collaborators.length,
                    itemBuilder: (context, index) {
                      final collab = _collaborators[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.transparent),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(collab['avatar']!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  collab['avatar']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.person, color: theme.colorScheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    collab['name']!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    collab['role']!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.secondary),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Chat with ${collab['name']} requested.')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/projects');
          } else if (index == 3) {
            Navigator.of(context).pushReplacementNamed('/ai-tools');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: theme.colorScheme.secondary,
        unselectedItemColor: theme.colorScheme.outline,
        selectedLabelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Network',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
        ],
      ),
    );
  }
}
