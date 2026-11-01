// ============================================================
// FIX IT IN PLAN - CHATBOT KNOWLEDGE BASE
// Add or edit topics here, not in chatbot.dart.
// ============================================================

String chatbotAnswerFor(String question) {
  final text = _normalize(question);
  final topic = _matchTopic(text);

  var tagalogScore = _countWords(text, _tagalogSignalWords);
  var englishScore = _countWords(text, _englishSignalWords);

  if (topic != null) {
    tagalogScore += 2 * _countPhraseHits(text, topic.tagalogKeywords);
    englishScore += _countPhraseHits(text, topic.englishKeywords);
  }

  final useTagalog = tagalogScore > 0 && tagalogScore >= englishScore;

  if (topic == null) {
    return useTagalog ? _outOfScopeTagalog : _outOfScopeEnglish;
  }
  return useTagalog ? topic.tagalogAnswer : topic.englishAnswer;
}

_ChatTopic? _matchTopic(String text) {
  _ChatTopic? best;
  int bestHits = 0;
  for (final topic in _topics) {
    final keywords = <String>{
      ...topic.englishKeywords,
      ...topic.tagalogKeywords,
    };
    final hits =
        keywords.where((keyword) => text.contains(' $keyword ')).length;
    if (hits > bestHits) {
      best = topic;
      bestHits = hits;
    }
  }
  return best;
}

String _normalize(String value) {
  final words = value
      .toLowerCase()
      .split(RegExp('[^a-z]+'))
      .where((word) => word.isNotEmpty)
      .join(' ');
  return ' $words ';
}

int _countWords(String text, Set<String> words) {
  return text.split(' ').where((word) => words.contains(word)).length;
}

int _countPhraseHits(String text, List<String> keywords) {
  return keywords.where((keyword) => text.contains(' $keyword ')).length;
}

// ============================================================
// BILINGUAL KNOWLEDGE BASE
// A Tagalog answer is kept for every topic so the reply can
// follow the language of the question.
// ============================================================

class _ChatTopic {
  const _ChatTopic({
    required this.englishKeywords,
    required this.tagalogKeywords,
    required this.englishAnswer,
    required this.tagalogAnswer,
  });

  final List<String> englishKeywords;
  final List<String> tagalogKeywords;
  final String englishAnswer;
  final String tagalogAnswer;
}

const List<_ChatTopic> _topics = [
  _ChatTopic(
    englishKeywords: ['foundation', 'footing'],
    tagalogKeywords: ['pundasyon', 'fundasyon', 'fundacion', 'batayan'],
    englishAnswer:
        'A foundation transfers building loads safely to the ground, while a footing is a part of the foundation that distributes the load over the soil.\n\n'
        'The proper foundation type depends on soil conditions, structural loads, site conditions, and the approved structural design. A licensed civil or structural engineer should evaluate the actual site before construction.',
    tagalogAnswer:
        'Ang pundasyon ang naglilipat ng bigat ng gusali sa lupa nang ligtas, samantalang ang footing ay bahagi ng pundasyon na nagkakalat ng bigat sa lupa.\n\n'
        'Depende ang tamang uri ng pundasyon sa kondisyon ng lupa, bigat ng istruktura, kalagayan ng site, at sa aprubadong structural design. Kailangang suriin ng lisensyadong civil o structural engineer ang aktuwal na lote bago magpundasyon.',
  ),
  _ChatTopic(
    englishKeywords: ['cement', 'concrete'],
    tagalogKeywords: ['semento', 'simiento', 'kongkreto', 'konkreto', 'konkrito', 'halo'],
    englishAnswer:
        'Concrete is commonly made from cement, aggregates, water, and sometimes admixtures. The required mix and strength depend on the intended structural application.\n\n'
        'For actual structural work, use the project specifications and the design prepared or approved by the responsible engineer.',
    tagalogAnswer:
        'Ang kongkreto ay karaniwang gawa sa semento, agregado (buhangin at gravel), tubig, at minsan ay admixture. Depende ang sukat ng halo at lakas nito sa kung saan ito gagamitin.\n\n'
        'Para sa aktuwal na structural na trabaho, sundin ang specifications ng proyekto at ang design na inihanda o aprubado ng responsible engineer.',
  ),
  _ChatTopic(
    englishKeywords: ['rebar', 'reinforcement', 'steel'],
    tagalogKeywords: ['rebar', 'bakal', 'refors', 'wire mesh'],
    englishAnswer:
        'Reinforcing steel, or rebar, is used with concrete to help resist tensile forces. Bar size, spacing, grade, and arrangement must come from the approved structural design rather than a general chatbot recommendation.',
    tagalogAnswer:
        'Ang rebar o bakal na ilalagay sa kongkreto ay tumutulong labanan ang tensile forces. Ang laki ng bakal, agwat (spacing), grade, at ayos nito ay dapat galing sa aprubadong structural design, hindi sa payo ng chatbot.',
  ),
  _ChatTopic(
    englishKeywords: ['lot', 'sqm', 'square meter', 'measurement', 'area', 'size'],
    tagalogKeywords: ['sukat', 'laki', 'lot', 'sqm', 'square', 'metro', 'lupa', 'area'],
    englishAnswer:
        'Lot size is commonly expressed in square meters (sqm). For example, a 10 m x 12 m rectangular lot has an area of 120 sqm.\n\n'
        'Actual building dimensions must also consider setbacks, easements, site conditions, and applicable regulations.',
    tagalogAnswer:
        'Ang sukat ng lote ay karaniwang sinusukat sa square meter (sqm). Halimbawa, ang lot na 10 m x 12 m ay may area na 120 sqm.\n\n'
        'Sa aktuwal na dimension ng bahay, isaisa rin ang setbacks, easements, kalagayan ng site, at mga applicable na regulasyon.',
  ),
  _ChatTopic(
    englishKeywords: ['permit'],
    tagalogKeywords: ['pahintulot', 'permiso', 'papeles', 'lisensya', 'permit'],
    englishAnswer:
        'A building project may require permits and supporting documents depending on the location, project type, and applicable regulations.\n\n'
        'For your actual project, check the requirements of the appropriate local authority and coordinate with the professionals handling your plans.',
    tagalogAnswer:
        'Depende sa lokasyon, uri ng proyekto, at mga lokal na regulasyon, maaaring kailanganin ng building permit at mga suportang dokumento.\n\n'
        'Para sa inyong aktuwal na proyekto, itanong sa tamang city o municipal office at sa mga propesyonal na hawak ng plano ninyo kung ano ang eksaktong requirements.',
  ),
  _ChatTopic(
    englishKeywords: ['revision', 'change'],
    tagalogKeywords: ['revision', 'revise', 'pagbabago', 'baguhin', 'bago', 'uli'],
    englishAnswer:
        'If you need a design or project change, you can use the Request Revision feature in Fix It In Plan. Describe the area you want changed and provide clear details so the project team can review the request.',
    tagalogAnswer:
        'Kung kailangan ninyong baguhin ang design o proyekto, pwede mong gamitin ang Request Revision feature sa Fix It In Plan. I-describe ang partikular na area na gusto ninyong baguhin at magbigay ng malinaw na detalye para agad masuri ng project team ang request ninyo.',
  ),
  _ChatTopic(
    englishKeywords: ['material', 'materials'],
    tagalogKeywords: ['materyales', 'materyal', 'bilihin', 'supply'],
    englishAnswer:
        'Construction materials should be selected based on the design, required performance, site conditions, availability, and project specifications.\n\n'
        'For structural materials, follow the specifications prepared or approved by the responsible engineer.',
    tagalogAnswer:
        'Ang pagpili ng construction materials ay dapat base sa design, kailangang tibay o performance, kalagayan ng site, availability, at specifications ng proyekto.\n\n'
        'Para sa structural materials, sundin ang specifications na inihanda o aprubado ng responsible engineer.',
  ),
  _ChatTopic(
    englishKeywords: ['process', 'construction', 'steps'],
    tagalogKeywords: ['proseso', 'pagtatayo', 'itatayo', 'hakbang', 'procedure'],
    englishAnswer:
        'A typical project may involve planning and design, site assessment, permits, construction, inspections, revisions when needed, and project completion.\n\n'
        'The exact sequence depends on the project and the professionals involved.',
    tagalogAnswer:
        'Karaniwang dumaan ang isang proyekto sa planning and design, site assessment, permits, pagtatayo, inspections, revisions kung kinakailangan, at project completion.\n\n'
        'Iba-iba ang eksaktong sunod-sunod depende sa proyekto at sa mga propesyonal na sangkot.',
  ),
  _ChatTopic(
    englishKeywords: ['cost', 'budget', 'price', 'estimate'],
    tagalogKeywords: ['presyo', 'magkano', 'gastos', 'gatad', 'bayad', 'budget', 'estimate'],
    englishAnswer:
        'Construction cost depends on factors such as floor area, design, materials, labor, site conditions, permits, and project specifications.\n\n'
        'A reliable project estimate should be prepared from the actual plans, quantities, specifications, and current local prices.',
    tagalogAnswer:
        'Ang gastos ng pagtatayo ay depende sa floor area, design, materyales, labor, kalagayan ng site, permits, at specifications ng proyekto.\n\n'
        'Ang maaasahang estimate ay dapat galing sa aktuwal na plano, quantities, specifications, at kasalukuyang presyo sa inyong lugar.',
  ),
  _ChatTopic(
    englishKeywords: ['status', 'progress', 'update'],
    tagalogKeywords: ['status', 'progress', 'update', 'tapos', 'tatapos', 'isatapos'],
    englishAnswer:
        'You can follow your project in the Client Dashboard, where the designs, files, and messages with the project team are listed. For a specific update, send a message to the team through the app so they can reply with the current progress.',
    tagalogAnswer:
        'Pwede ninyong sundan ang inyong proyekto sa Client Dashboard. Doon makikita ang designs, files, at mga message ninyo ng project team. Para sa partikular na update, mag-send ng message sa app para masagot ninyo ng team kung saan na ang proseso.',
  ),
  _ChatTopic(
    englishKeywords: ['payment', 'downpayment', 'balance', 'terms'],
    tagalogKeywords: ['bayad', 'bayaran', 'deposit', 'balance', 'partial', 'terms'],
    englishAnswer:
        'Payment terms, schedule, and remaining balance are part of your project agreement. Open your project details or message the project team through the app to confirm the amount and the due date.',
    tagalogAnswer:
        'Ang terms, schedule, at natitirang balance ng bayad ay bahagi ng inyong project agreement. Buksan ang project details o mag-message sa project team sa app para ma-kumpirma ang halaga at kailan ito dapat bayaran.',
  ),
  _ChatTopic(
    englishKeywords: ['timeline', 'deadline', 'how long', 'duration'],
    tagalogKeywords: ['kailan', 'tagal', 'deadline', 'timeline', 'matatapos'],
    englishAnswer:
        'Project duration depends on its size, design complexity, permits, weather, and the team schedule. The agreed timeline and milestones should be reflected in your project agreement and dashboard.',
    tagalogAnswer:
        'Ang tagal ng proyekto ay depende sa laki, kumplikasyon ng design, permits, panahon, at schedule ng team. Ang napag-usapang timeline at milestones ay dapat makikita sa inyong project agreement at dashboard.',
  ),
  _ChatTopic(
    englishKeywords: ['hello', 'hi', 'help'],
    tagalogKeywords: ['kumusta', 'kamusta', 'tulong'],
    englishAnswer:
        'Sure! You can ask me about general civil engineering and construction topics such as foundations, concrete, rebar, materials, measurements, permits, project process, and revisions.',
    tagalogAnswer:
        'Sige! Pwede ninyong itanong sa akin ang general civil engineering at construction topics tulad ng pundasyon, kongkreto, rebar, materyales, sukat ng lote, permits, proseso ng proyekto, gastos, at revisions.',
  ),
];

// The assistant is scoped to house construction only: a question that
// matches no topic gets this refusal, in the language it was asked.
const String _outOfScopeEnglish =
    'I only answer questions about building a house and civil engineering:'
    ' foundation, concrete, rebar, materials, lot size, permits, cost,'
    ' revisions, and project progress.\n\n'
    ' I cannot answer topics outside that scope. For anything about your'
    ' actual project, please message your project team through the app.';

const String _outOfScopeTagalog =
    'Sagot ko lang ang mga tanong tungkol sa pagtatayo ng bahay at civil'
    ' engineering: pundasyon, kongkreto, rebar, materyales, sukat ng lote,'
    ' permit, gastos, revision, at progress ng proyekto.\n\n'
    ' Hindi ako makakapagbigay ng sagot sa labas ng sakop na iyan. Para sa'
    ' mga kailangan sa inyong aktuwal na proyekto, mag-message sa project'
    ' team ninyo sa app.';

// Words that rarely appear in English sentences. Any hit means the
// client is typing Tagalog or Taglish, so the reply switches language.
const Set<String> _tagalogSignalWords = {
  'ako', 'ang', 'ng', 'sa', 'po', 'ho', 'kasi', 'para', 'mga', 'meron', 'may',
  'wala', 'hindi', 'di', 'pwede', 'puwede', 'gusto', 'ay', 'na', 'pa', 'din',
  'rin', 'lang', 'ito', 'niyan', 'niyo', 'ninyo', 'namin', 'natin', 'tayo',
  'yung', 'magkano', 'gaano', 'ilan', 'saan', 'bakit', 'paano', 'salamat',
  'kumusta', 'kamusta', 'gawa', 'gagawa', 'gagawin', 'tapos', 'tatapos',
  'bukas', 'kanina', 'ngayon', 'kasama', 'tuloy', 'sana', 'ba', 'pala', 'kayo',
  'siya', 'parang', 'kaya', 'talaga', 'paki', 'sino', 'alin', 'kanino',
};

const Set<String> _englishSignalWords = {
  'the', 'a', 'an', 'is', 'are', 'was', 'were', 'what', 'how', 'why', 'when',
  'where', 'for', 'to', 'of', 'in', 'on', 'i', 'my', 'me', 'you', 'your', 'we',
  'do', 'does', 'can', 'could', 'need', 'want', 'please', 'tell', 'explain',
  'much', 'many', 'long', 'use', 'used', 'with', 'and', 'or', 'about', 'this',
  'that', 'there', 'it', 'its',
};

