class Symptom {
  final String name;
  final List<String>? subSymptoms;

  Symptom(this.name, [this.subSymptoms]);
}

final List<Symptom> symptoms = [
  // Emotional and Mental Health
  Symptom("Emotional and Mental Health", [
    "Anxiety and nervousness",
    "Depression",
    "Emotional symptoms",
    "Restlessness",
    "Hostile behavior",
    "Fears and phobias",
    "Low self-esteem",
    "Obsessions and compulsions",
    "Antisocial behavior",
    "Hysterical behavior",
    "Sleepwalking",
    "Nightmares",
  ]),

  // Breathing Problems
  Symptom("Breathing Problems", [
    "Shortness of breath",
    "Breathing fast",
    "Wheezing",
    "Chest tightness",
    "Hoarse voice",
    "Sore throat",
    "Cough",
    "Nasal congestion",
    "Throat swelling",
    "Difficulty speaking",
    "Coughing up sputum",
    "Apnea",
    "Congestion in chest",
    "Flu-like syndrome",
    "Burning chest pain",
  ]),

  // Heart and Blood Circulation
  Symptom("Heart and Blood Circulation", [
    "Palpitations",
    "Irregular heartbeat",
    "Chest pain",
    "Dizziness",
    "Sharp chest pain",
    "Increased heart rate",
    "Decreased heart rate",
    "Peripheral edema",
    "Low back weakness",
    "Feeling cold",
    "Blood clots during menstrual periods",
    "Poor circulation",
  ]),

  // Stomach and Digestion
  Symptom("Stomach and Digestion", [
    "Nausea",
    "Vomiting",
    "Diarrhea",
    "Abdominal pain",
    "Flatulence",
    "Stomach bloating",
    "Burning abdominal pain",
    "Blood in stool",
    "Changes in stool appearance",
    "Swollen abdomen",
    "Constipation",
    "Melena",
    "Regurgitation",
  ]),

  // Urinary and Reproductive Health
  Symptom("Urinary and Reproductive Health", [
    "Retention of urine",
    "Frequent urination",
    "Painful urination",
    "Blood in urine",
    "Scanty menstrual flow",
    "Vaginal pain",
    "Vaginal discharge",
    "Involuntary urination",
    "Pain during intercourse",
    "Menstrual irregularities",
    "Pelvic pain",
    "Vaginal itching",
    "Vaginal dryness",
    "Penis pain",
    "Premature ejaculation",
  ]),

  // Bones, Joints, and Muscles
  Symptom("Bones, Joints, and Muscles", [
    "Leg pain",
    "Hip pain",
    "Back pain",
    "Joint pain",
    "Muscle pain",
    "Shoulder pain",
    "Wrist pain",
    "Arm pain",
    "Stiffness or tightness (various locations)",
    "Weakness (various locations)",
    "Cramps or spasms (various locations)",
    "Swelling (various locations)",
  ]),

  // Skin, Hair, and Nails
  Symptom("Skin, Hair, and Nails", [
    "Rash",
    "Itching",
    "Skin swelling",
    "Skin moles",
    "Acne or pimples",
    "Dry skin",
    "Redness",
    "Skin lesions",
    "Changes in skin mole size or color",
    "Skin irritation",
    "Wrinkles",
  ]),

  // Nervous System and Brain
  Symptom("Nervous System and Brain", [
    "Fainting",
    "Seizures",
    "Headache",
    "Disturbance of memory",
    "Slurring words",
    "Side pain",
    "Paresthesia",
    "Loss of sensation",
    "Muscle weakness",
    "Stuttering or stammering",
  ]),

  // Eyes and Vision
  Symptom("Eyes and Vision", [
    "Double vision",
    "Diminished vision",
    "Eye redness",
    "Pain in eye",
    "Swollen eye",
    "Blindness",
    "Spots or clouds in vision",
    "Eye burns or stings",
  ]),

  // Ears and Hearing
  Symptom("Ears and Hearing", [
    "Diminished hearing",
    "Ringing in ears",
    "Plugged feeling in ears",
    "Redness in ear",
    "Fluid in ear",
    "Itchy ears",
  ]),

  // Babies and Children
  Symptom("Babies and Children", [
    "Infant spitting up",
    "Irritable infant",
    "Symptoms of infants",
    "Diaper rash",
    "Pulling at ears",
    "Recent pregnancy",
  ]),

  // Women's Health
  Symptom("Women's Health", [
    "Symptoms during pregnancy",
    "Spotting during pregnancy",
    "Pain during pregnancy",
    "Pelvic pressure",
    "Postpartum problems",
    "Vaginal bleeding after menopause",
  ]),

  // General Symptoms
  Symptom("General Symptoms", [
    "Fatigue",
    "Fever",
    "Chills",
    "Weight gain",
    "Recent weight loss",
    "Feeling ill",
    "Weakness",
    "Restlessness",
    "Sweating",
    "Hot flashes",
    "Feeling hot and cold",
    "Thirst",
  ]),
];
