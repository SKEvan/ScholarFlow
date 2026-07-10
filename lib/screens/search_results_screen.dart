import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;
  String _selectedTab = 'All';
  
  // Track active/inactive filter chips
  final Map<String, bool> _filters = {
    'Last Year': false,
    'Open Access': false,
    'Peer Reviewed': false,
  };

  final List<Map<String, dynamic>> _papers = [
    {
      'title': 'Quantum Entanglement in Macro Systems',
      'authors': 'Dr. Julian Vance, et al.',
      'year': '2023',
      'tags': ['#Physics', '#Quantum'],
      'abstract': 'This study explores the decoherence-resistant properties of entangled states in large-scale lattices...',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAmI51Hy_3V3_mPiEVS-HOb152wOCnk9FBtwHWJGHCxzHFKJFR-0zwkkRgBvLnRrIlDJjhUd3AQzs204ZNbkUDnPWFioVTbD3P7ZNmmbDQWHdHswKu2yqbZubmtjasXZzYQaavE8OV6QYoyoGWnZDExkbUX6MDytURAxIbwfjFZFX0PnW6aXuLbZShLhRNBYN1kwNQ8LuTAI80R9F9MKuPYkMZ3s6RTh25hSobVEZZU__oa_0CDm0xXM8HCsBnVtZFX6eQ_7YVPylc',
      'citation': 'Vance, J., et al. (2023). Quantum Entanglement in Macro Systems. Journal of Quantum Physics, 45(1), 12-28.',
      'summary': 'This research successfully demonstrates macro-scale quantum entanglement preservation across silicon lattices under ambient room temperatures. Key findings reveal a 34% increase in coherence duration when coupled with thermal isolation shielding.',
    },
    {
      'title': 'Neural Pathways in Decision Making',
      'authors': 'Sarah Chen, et al.',
      'year': '2022',
      'tags': ['#Neuroscience', '#Cognitive'],
      'abstract': 'Analyzing synaptic firing rates to map automated decision patterns in primary cortex networks.',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBogvkBFfOcZs-M_DiyeNxoMxVEAii9pqKG1IG86-JB1zHqSvJjKYS89CvYmZZ8DvB_Dx1f7iYuTHUG359D9q4KkeDsbE8KfHVriKqKeJDti6hdPKiO0_v_1pfcrYSwuHc52wAUguNDE3YUq0vJv-btySn11UGJtbxcPs_DZFyfkLLxbaZ7CrAKMMa5B3UCMDFZ_wp7npAOIeWLFunTv_qsa8n1mawhtEtFqXxQNPFleU3WNamxgmIIeCMKWpuvG4ETAx-clpTx7jo',
      'citation': 'Chen, S., et al. (2022). Neural Pathways in Decision Making. Cognitive Science Letters, 18(3), 204-219.',
      'summary': 'The authors map Primary Motor Cortex synaptic responses to high-speed visual cues in primates. The data confirms the existence of a pre-decisive neural bridge that initiates automated motor routines 200ms prior to conscious selection.',
    },
    {
      'title': 'Algorithmic Bias in Quantum Models',
      'authors': 'Prof. Aris',
      'year': '2024',
      'tags': ['#AI', '#Ethics'],
      'abstract': 'Identifying and correcting bias in high-dimensional state space mapping algorithms.',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCgaUjeAuzPWcclCTkDJGVn2G0akpZu1iLWbxvTsEZalqFfn24OaJR7c4g7LzcRsXgTc9sCS7iJfHe71-8oUqmiQfNRD3psqL2MNXGsBQCZUbLnVFxScINih_eEGFxcz3jkikc600wBml407_MFM0lMW3a9pOTzr5uy06ZWIuYPshHKm-u12H0J_eKU7R-0xfgspaR3Q6NtrCp7Qr5HXDt-TDa_3nMCQGcOx9cmBF1Nj-1kQwrhxDA57ibSyLG4WoLiShScpJQBLGU',
      'citation': 'Aris, P. (2024). Algorithmic Bias in Quantum Models. Ethical Computing & Quantum Systems, 30(4), 89-102.',
      'summary': 'This critical study outlines how bias propagates through non-linear Hilbert projections in quantum ML pipelines. It proposes a mathematically verified projection constraint to enforce equal parity metrics across state distributions.',
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    _searchController = TextEditingController(text: args ?? 'Quantum');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCiteDialog(String citation) {
    Clipboard.setData(ClipboardData(text: citation));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Citation copied to clipboard!')),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.format_quote, color: Colors.blue),
            SizedBox(width: 8),
            Text('Citation Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              citation,
              style: const TextStyle(height: 1.4, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            const Text(
              'Successfully copied to clipboard.',
              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSummaryDialog(String title, String summaryText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.psychology, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 8),
            const Text('AI Summary'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Text(
              summaryText,
              style: const TextStyle(height: 1.4, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(104),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top Search Bar Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: theme.colorScheme.outline, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.border_horizontal, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
                // Tabs Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildTabItem('All'),
                      const SizedBox(width: 24),
                      _buildTabItem('Papers'),
                      const SizedBox(width: 24),
                      _buildTabItem('Projects'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: _filters.keys.map((filter) {
                  final isSelected = _filters[filter]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Row(
                        children: [
                          Text(filter),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filters[filter] = selected;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Projects Section
            if (_selectedTab == 'All' || _selectedTab == 'Projects') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Projects',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'View all',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantum Neural Networks',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hybrid Computing Initiative',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PROGRESS',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            '92%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.92,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuD2IWoCsrUH-vfr-cu0dfbXVrv1kudyOZKA8-f4VZL87YhIoUGebw9VZ3uN51f2bj2YWc3rh-Wjcrja0viPq3hdETZP_dIdlG0e3ihnl63MRhaCLhf-el4TK3wtv-SE965DPjw3DHD6VbMJZ2qjx_O65Sv8VSClAw02m7Ku9bs8O8J53-OHJu9gSGa3fzSRYT3zsn8lq5JOmmr22Q7MPAEpNzi5-OHmr6KY28x-wsjgLSgELIoxdi899zQNpqZ43oBxZmy0Gu7QgPk'),
                          Transform.translate(
                            offset: const Offset(-8, 0),
                            child: _buildAvatar('https://lh3.googleusercontent.com/aida-public/AB6AXuAg5suJXnYCCqmZY2x6eSr8mGfQcfdbsA-QaH0FQpTBXRf4Xd8XS8PGkXfHPt6HOYTW4IHcJbGmVMDO7oAsRIZgj5f-wIrFq3z-2kayjACPXJfFbtJLS4EgRACdjbbsqaLA_HwAR_9HOA6ySipheVERon0JTjmFY3s_2iiGLtZqXXAAYaq3vNVcsPZzt7I7fK4FiK4m24bCAt4x-Ozfeu76P4B308coAwkEH318NXOiTvM96bpiVGeci5b423rdvxfU_bwEjWIwo6w'),
                          ),
                          Transform.translate(
                            offset: const Offset(-16, 0),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.colorScheme.outlineVariant,
                              child: const Text(
                                '+4',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Papers Section
            if (_selectedTab == 'All' || _selectedTab == 'Papers') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Research Papers',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _papers.length,
                itemBuilder: (context, index) {
                  final paper = _papers[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                paper['title']!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${paper['authors']} • ${paper['year']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: (paper['tags'] as List<String>).map((tag) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 6.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 10,
                                        color: theme.colorScheme.outline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (paper['abstract'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '"${paper['abstract']}"',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.outline,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showCiteDialog(paper['citation']!),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.format_quote, size: 16),
                                    label: const Text('Cite', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () => _showSummaryDialog(paper['title']!, paper['summary']!),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(color: theme.colorScheme.outline),
                                    ),
                                    child: const Text('Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              paper['imageUrl']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image, color: theme.colorScheme.outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedTab == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 3.0,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 16),
        ),
      ),
    );
  }
}
