import 'package:flutter/material.dart';

import '../models/article_item.dart';
import '../models/forum_category.dart';
import '../models/thread_item.dart';

abstract final class MockData {
  static const siteName = 'Lilmod Ulilamed';
  static const tagline =
      'An intellectual community for serious, respectful Torah discourse.';

  static const communityStandards = [
    'Intellectual rigor and honest inquiry',
    'Respectful disagreement without ad hominem',
    'Torah-bound discussion',
  ];

  static const forumStats = {
    'threads': 51,
    'posts': 313,
    'articles': 5,
    'members': 54,
    'online': 2,
  };

  static const onlineMembers = ['Lilmod Ulilamed', 'שאו מרום עיניכם'];

  static const recentThreads = [
    ThreadItem(
      id: '90',
      title: 'Concordance of משניות',
      type: 'Question',
      forumName: 'Gemara',
      date: 'Jun 29, 2026 1:56 PM',
      postCount: 3,
      viewCount: 11,
      latestActivity: '17 minutes ago',
      openedBy: 'שאו מרום עיניכם',
      latestBy: 'יֶ֣רַח בֶּן־יוֹמ֪וֹ',
      accentColor: Color(0xFF2F80ED),
      isNew: true,
    ),
    ThreadItem(
      id: '87',
      title: 'resources for שבעה עשר בתמוז',
      type: 'Discussion',
      forumName: 'Fast Days and Bein HaMetzarim',
      date: 'Jun 26, 2026 12:59 AM',
      postCount: 2,
      viewCount: 26,
      latestActivity: '1 hour, 12 minutes ago',
      openedBy: 'Yosheiv vDoreish',
      latestBy: 'Yosheiv vDoreish',
      accentColor: Color(0xFF4B78A8),
    ),
    ThreadItem(
      id: '85',
      title:
          'Length of the average Lunation (time between one molad and next molad)',
      type: 'Discussion',
      forumName: 'Zemanim, Calendar, and Astronomy',
      date: 'Jun 24, 2026 5:05 PM',
      postCount: 22,
      viewCount: 93,
      latestActivity: '2 hours, 41 minutes ago',
      openedBy: 'שאו מרום עיניכם',
      latestBy: 'שאו מרום עיניכם',
      accentColor: Color(0xFF8A63D2),
    ),
    ThreadItem(
      id: '89',
      title: 'Chumashim with Maps',
      type: 'Discussion',
      forumName: 'Manuscripts and Old Prints',
      date: 'Jun 28, 2026 10:50 AM',
      postCount: 9,
      viewCount: 40,
      latestActivity: '5 hours, 48 minutes ago',
      openedBy: 'Philo',
      latestBy: 'Philo',
      accentColor: Color(0xFF3D8B55),
    ),
    ThreadItem(
      id: '79',
      title: 'בענין היתר מנהג ואיסור דרבנן במקום מחלוקת',
      type: 'Discussion',
      forumName: 'Halachah Articles',
      date: 'Jun 22, 2026 6:55 PM',
      postCount: 3,
      viewCount: 41,
      latestActivity: '11 hours, 26 minutes ago',
      openedBy: 'לומד טוב',
      latestBy: 'יֶ֣רַח בֶּן־יוֹמ֪וֹ',
      accentColor: Color(0xFFC4667B),
    ),
    ThreadItem(
      id: '35',
      title: "R' Yaakov Emden largely corroborates the Potocki tradition",
      type: 'Discussion',
      forumName: 'Historical Documents',
      date: 'May 25, 2026 5:22 PM',
      postCount: 8,
      viewCount: 188,
      latestActivity: '15 hours, 24 minutes ago',
      openedBy: 'Philo',
      latestBy: 'Leib Shachar',
      accentColor: Color(0xFFB7791F),
    ),
  ];

  static const popularThreads = [
    SidebarThread(
      id: '49',
      title:
          'Errors in Academic Works Due To Unfamiliarity With The Classic Sources',
      forumName: 'Errata and Corrections',
      stats: '305 views · 13 posts · 3 days, 10 hours ago',
      accentColor: Color(0xFF3D8B55),
    ),
    SidebarThread(
      id: '48',
      title: 'Torah Tavlin?',
      forumName: 'Gemara',
      stats: '291 views · 19 posts · 6 days, 20 hours ago',
      accentColor: Color(0xFF2F80ED),
    ),
    SidebarThread(
      id: '52',
      title: 'גליון עלים - מכון עלה זית',
      forumName: 'Weekly Pamphlets',
      stats: '266 views · 6 posts · 3 days, 11 hours ago',
      accentColor: Color(0xFF4B78A8),
    ),
    SidebarThread(
      id: '35',
      title: "R' Yaakov Emden largely corroborates the Potocki tradition",
      forumName: 'Historical Documents',
      stats: '188 views · 8 posts · 15 hours, 24 minutes ago',
      accentColor: Color(0xFFB7791F),
    ),
    SidebarThread(
      id: '64',
      title: 'Double names',
      forumName: 'Finding Sources',
      stats: '203 views · 15 posts · 1 week ago',
      accentColor: Color(0xFF4B78A8),
    ),
    SidebarThread(
      id: '27',
      title: "Rav Aharon Kotler and Carlebach's Lulai Sorascha",
      forumName: 'Gedolim and Rabbanim',
      stats: '302 views · 9 posts · 2 weeks, 3 days ago',
      accentColor: Color(0xFF1D9BD1),
    ),
    SidebarThread(
      id: '85',
      title:
          'Length of the average Lunation (time between one molad and next molad)',
      forumName: 'Zemanim, Calendar, and Astronomy',
      stats: '93 views · 22 posts · 2 hours, 41 minutes ago',
      accentColor: Color(0xFF8A63D2),
    ),
  ];

  static const sourceRequests = [
    SidebarThread(
      id: '64',
      title: 'Double names',
      forumName: '',
      stats: '1 week ago',
      accentColor: Color(0xFF4B78A8),
    ),
    SidebarThread(
      id: '27',
      title: "Rav Aharon Kotler and Carlebach's Lulai Sorascha",
      forumName: '',
      stats: '2 weeks, 3 days ago',
      accentColor: Color(0xFF1D9BD1),
    ),
  ];

  static const featuredArticles = [
    ArticleItem(
      slug: 'kavod-hatzibbur',
      title: 'Kavod Hatzibbur',
      category: 'Halacha',
      date: 'Jun 20, 2026',
      accentColor: Color(0xFF8A63D2),
    ),
    ArticleItem(
      slug: 'on-semichas-geulah-ltfillah',
      title: "On Semichas Geulah L'tfillah",
      category: 'Aggadah and Derush',
      date: 'Jun 15, 2026',
      accentColor: Color(0xFFC4667B),
    ),
    ArticleItem(
      slug: 'hats-jackets-and-gartels-in-halacha',
      title: 'Hats Jackets and Gartels in Halacha',
      category: 'Halacha',
      date: 'Jun 5, 2026',
      accentColor: Color(0xFF2F80ED),
      excerpt:
          'An understanding of the halachos related to dress during prayer, according to all communities.',
    ),
  ];

  static const allArticles = [
    ...featuredArticles,
    ArticleItem(
      slug: 'sample-article',
      title: 'Sample Article',
      category: 'Machshavah',
      date: 'May 1, 2026',
      accentColor: Color(0xFF3D8B55),
    ),
    ArticleItem(
      slug: 'another-article',
      title: 'Another Article',
      category: 'Historical Studies',
      date: 'Apr 12, 2026',
      accentColor: Color(0xFFB7791F),
    ),
  ];

  static const forumCategories = [
    ForumCategory(
      name: 'Beis HaMidrash',
      description:
          'Sugya discussion, mareh mekomos, lomdus, Chazal, Rishonim, Acharonim, and general Torah analysis.',
      subforums: [
        ForumSubforum(
          name: 'Gemara',
          description:
              'Sugya discussion, Rishonim, Acharonim, nusach, and realia.',
          threadCount: 5,
          postCount: 51,
        ),
        ForumSubforum(
          name: 'Mareh Mekomos',
          description:
              'Organized source trails, reference lists, and guided mareh mekomos on sugyos and topics.',
          threadCount: 0,
          postCount: 0,
        ),
        ForumSubforum(
          name: 'Aggadah and Midrash',
          description:
              'Discussion of aggadic sugyos, Midrash, Chazal, and their interpretation.',
          threadCount: 2,
          postCount: 8,
        ),
        ForumSubforum(
          name: 'Daf Yomi, Oraysa, Dirshu, etc.',
          description:
              'Notes, questions, and discussion connected to Daf Yomi, Oraysa, Dirshu, and other structured learning programs.',
          threadCount: 1,
          postCount: 3,
        ),
        ForumSubforum(
          name: 'Short Questions and Notes',
          description:
              'Brief Torah questions, quick observations, short chiddushim, and developing notes.',
          threadCount: 2,
          postCount: 5,
        ),
      ],
    ),
    ForumCategory(
      name: 'Parashah and Tanach',
      description:
          "Discussion of Chumash, Rashi, Targumim, meforshim, Midrashim on Chumash and Nach, parashah, Nevi'im, and Kesuvim.",
      subforums: [
        ForumSubforum(
          name: 'Chumash, Rashi, Targumim, and Other Meforshim',
          description:
              'Discussion of Chumash, Rashi, Targumim, classic meforshim, and related explanatory issues.',
          threadCount: 2,
          postCount: 7,
        ),
        ForumSubforum(
          name: 'Midrashim on Chumash and Nach',
          description:
              'Discussion of Midrashim connected to Chumash, Nevi\'im, Kesuvim, and the weekly parashah.',
          threadCount: 0,
          postCount: 0,
        ),
        ForumSubforum(
          name: "Nevi'im and Kesuvim",
          description:
              'Study and discussion of Nach, meforshim, and historical background.',
          threadCount: 1,
          postCount: 2,
        ),
        ForumSubforum(
          name: 'Weekly Parashah',
          description: 'Parashah discussion, divrei Torah, and questions.',
          threadCount: 0,
          postCount: 0,
        ),
      ],
    ),
    ForumCategory(
      name: 'Halachah and Minhag',
      description:
          'Current and perennial halachic discussion, minhagim, practical questions, and analysis of poskim.',
      subforums: [
        ForumSubforum(
          name: 'Sugyos in Halachah',
          description:
              'Discussion of halachic sugyos, Shulchan Aruch, Nosei Keilim, teshuvos, and later poskim.',
          threadCount: 0,
          postCount: 0,
        ),
        ForumSubforum(
          name: 'Contemporary Halachic Questions',
          description: 'Contemporary halachic questions and practical issues.',
          threadCount: 4,
          postCount: 20,
        ),
        ForumSubforum(
          name: 'Historical Halachic Questions and Controversies',
          description:
              'Earlier halachic questions, controversies, disputes, and their development in the sources.',
          threadCount: 2,
          postCount: 7,
        ),
      ],
    ),
    ForumCategory(
      name: 'Mekoros and Source-Finding',
      description:
          'Finding sources, identifying quotations, tracing ideas, locating mareh mekomos, and sharing permitted resources.',
      subforums: [
        ForumSubforum(
          name: 'Finding Sources',
          description:
              'Source requests, source trails, quotations, and practical bibliography help.',
          threadCount: 3,
          postCount: 23,
        ),
        ForumSubforum(
          name: 'Where Is This From? / Lost References',
          description:
              'Identifying unknown quotations, unattributed ideas, vague references, forgotten sources, and half-remembered mareh mekomos.',
          threadCount: 2,
          postCount: 9,
        ),
      ],
    ),
  ];
}
