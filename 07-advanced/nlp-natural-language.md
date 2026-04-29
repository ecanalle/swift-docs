# Natural Language Processing - NLP & Text Analysis 🎯

## Overview
Natural Language Processing (NLP) in iOS enables your app to analyze, interpret, and process human language. From sentiment analysis to entity recognition, NLP transforms raw text into actionable insights for smarter user experiences.

## Main Topics
- [Natural Language Framework](#natural-language-framework) - Core NLP capabilities
- [Text Analysis Fundamentals](#text-analysis-fundamentals) - Tokenization and tagging
- [Sentiment and Entity Recognition](#sentiment-and-entity-recognition) - Understanding meaning
- [Language Detection](#language-detection) - Identifying languages
- [Custom NLP Models](#custom-nlp-models) - Core ML integration
- [Best Practices](#-best-practices) - Optimizing NLP operations
- [Common Mistakes](#-common-mistakes-anti-patterns) - Avoiding pitfalls

## Official Documentation
- [Apple: Natural Language Framework](https://developer.apple.com/documentation/naturallanguage)
- [Apple: Core ML](https://developer.apple.com/documentation/coreml)
- [WWDC 2019: Advances in Natural Language Framework](https://developer.apple.com/videos/play/wwdc2019/232)

---

## Natural Language Framework

### Core NLP Capabilities

The `NaturalLanguage` framework provides built-in support for:
- **Tokenization** - Breaking text into meaningful units (words, sentences)
- **Part-of-speech tagging** - Identifying nouns, verbs, adjectives, etc.
- **Named entity recognition** - Extracting people, places, organizations
- **Language identification** - Detecting what language text is written in

```swift
// ✅ Correct: Using Natural Language framework efficiently
import NaturalLanguage

let text = "Apple CEO Tim Cook announced new products in San Francisco."
let tagger = NLTagger(tagSchemes: [.nameType, .posTag, .tokenType])
tagger.string = text

// Tokenize and identify parts of speech
var tags: [String: [String]] = [:]
tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .posTag) { tag, range in
    let word = String(text[range])
    if let tag = tag {
        tags[tag.rawValue, default: []].append(word)
    }
    return true
}

// Extract named entities
tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
    if let tag = tag {
        let entity = String(text[range])
        print("Entity: \(entity) (\(tag.rawValue))")
    }
    return true
}
```

**Key Points:**
- Tagging is synchronous and fast for typical text lengths
- Multiple tag schemes can be combined for richer analysis
- Language detection should precede other operations for accuracy

### Language Detection

```swift
// ✅ Correct: Detecting language before processing
import NaturalLanguage

func analyzeText(_ text: String) {
    let languageRecognizer = NLLanguageRecognizer()
    languageRecognizer.processString(text)
    
    guard let language = languageRecognizer.dominantLanguage else {
        print("Could not detect language")
        return
    }
    
    print("Detected language: \(language.rawValue)")
    
    // Now process with appropriate tagger
    let tagger = NLTagger(tagSchemes: [.lemma, .posTag])
    tagger.string = text
    tagger.string = text
    
    tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma) { tag, range in
        if let tag = tag {
            let word = String(text[range])
            let lemma = tag.rawValue
            print("Word: \(word), Lemma: \(lemma)")
        }
        return true
    }
}

// Usage
analyzeText("The user is happy with the application")
```

---

## Text Analysis Fundamentals

### Tokenization

Tokenization breaks text into meaningful units. Different units are useful for different purposes.

```swift
// ✅ Correct: Proper tokenization for different use cases
import NaturalLanguage

let text = "Hello, world! How are you?"
let tagger = NLTagger(tagSchemes: [.tokenType])
tagger.string = text

// Word-level tokenization
print("Words:")
tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .tokenType) { tag, range in
    let word = String(text[range])
    print("  - \(word)")
    return true
}

// Sentence-level tokenization
print("\nSentences:")
tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .tokenType) { tag, range in
    let sentence = String(text[range])
    print("  - \(sentence.trimmingCharacters(in: .whitespaces))")
    return true
}

// Paragraph-level tokenization
print("\nParagraphs:")
tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .tokenType) { tag, range in
    let paragraph = String(text[range])
    print("  - \(paragraph.trimmingCharacters(in: .whitespaces))")
    return true
}
```

### Part-of-Speech Tagging

```swift
// ✅ Correct: Analyzing grammar to understand text structure
import NaturalLanguage

let sentence = "The quick brown fox jumps over the lazy dog"
let tagger = NLTagger(tagSchemes: [.posTag])
tagger.string = sentence

var grammar: [String: [String]] = [:]

tagger.enumerateTags(in: sentence.startIndex..<sentence.endIndex, unit: .word, scheme: .posTag) { tag, range in
    let word = String(sentence[range])
    if let tag = tag {
        let partOfSpeech = tag.rawValue
        grammar[partOfSpeech, default: []].append(word)
    }
    return true
}

for (pos, words) in grammar.sorted(by: { $0.key < $1.key }) {
    print("\(pos): \(words.joined(separator: ", "))")
}
```

---

## Sentiment and Entity Recognition

### Named Entity Recognition (NER)

```swift
// ✅ Correct: Extracting entities from text
import NaturalLanguage

let text = """
Steve Jobs, co-founder of Apple Inc., was born in San Francisco. 
He worked with Steve Wozniak to create the first personal computer.
"""

let tagger = NLTagger(tagSchemes: [.nameType])
tagger.string = text

var entities: [String: [String]] = [:]

tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
    if let tag = tag {
        let entity = String(text[range])
        let type = tag.rawValue
        entities[type, default: []].append(entity)
    }
    return true
}

for (type, values) in entities {
    print("\(type):")
    for value in Set(values) {  // Remove duplicates
        print("  - \(value)")
    }
}
```

**Output:**
```
Organization:
  - Apple Inc.
Person:
  - Steve Jobs
  - Steve Wozniak
Place:
  - San Francisco
```

### Sentiment Analysis with Core ML

```swift
// ✅ Correct: Using trained model for sentiment analysis
import CoreML
import NaturalLanguage

class SentimentAnalyzer {
    let model: MLModel
    
    init(modelName: String) throws {
        // Load your custom sentiment model
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw NSError(domain: "Model not found", code: -1)
        }
        self.model = try MLModel(contentsOf: modelURL)
    }
    
    func analyzeSentiment(_ text: String) throws -> (sentiment: String, confidence: Double) {
        // Preprocess text if needed
        let input = SentimentModelInput(text: text)
        let output = try model.prediction(from: input)
        
        // Extract sentiment label and confidence
        if let output = output as? SentimentModelOutput {
            return (output.label, output.confidence)
        }
        
        throw NSError(domain: "Invalid output", code: -1)
    }
}

// Usage
let analyzer = try SentimentAnalyzer(modelName: "SentimentModel")
let (sentiment, confidence) = try analyzer.analyzeSentiment("This app is amazing!")
print("Sentiment: \(sentiment) (confidence: \(String(format: "%.2f", confidence)))")
```

---

## Language Detection

### Identifying Text Language

```swift
// ✅ Correct: Detecting and handling multiple languages
import NaturalLanguage

func detectLanguageAndAnalyze(_ text: String) {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    
    // Get dominant language
    if let language = recognizer.dominantLanguage {
        print("Primary language: \(language.rawValue)")
    }
    
    // Get all detected languages with probabilities
    let languages = recognizer.languageHypotheses(withMaximum: 3)
    print("\nLanguage probabilities:")
    for (language, probability) in languages {
        print("  - \(language.rawValue): \(String(format: "%.2f", probability))")
    }
    
    // Adjust processing based on language
    let tagger = NLTagger(tagSchemes: [.lemma])
    tagger.language = recognizer.dominantLanguage
    tagger.string = text
    
    // Process accordingly
    tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma) { tag, range in
        let word = String(text[range])
        let lemma = tag?.rawValue ?? "unknown"
        print("Word: \(word) → Lemma: \(lemma)")
        return true
    }
}

// Usage
detectLanguageAndAnalyze("Hello, how are you today?")
detectLanguageAndAnalyze("Hola, ¿cómo estás hoy?")
detectLanguageAndAnalyze("Bonjour, comment allez-vous?")
```

---

## Custom NLP Models

### Integrating Core ML Models

```swift
// ✅ Correct: Using custom-trained NLP models with Core ML
import CoreML
import NaturalLanguage

class TextClassifier {
    let model: MLModel
    
    init(modelName: String) throws {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw ClassifierError.modelNotFound
        }
        self.model = try MLModel(contentsOf: modelURL)
    }
    
    func classify(_ text: String) throws -> (category: String, confidence: [String: Double]) {
        let input = TextClassificationInput(text: text)
        let output = try model.prediction(from: input) as! TextClassificationOutput
        
        return (category: output.label, confidence: output.probabilities)
    }
    
    func batchClassify(_ texts: [String]) throws -> [(text: String, category: String)] {
        return try texts.map { text in
            let (category, _) = try classify(text)
            return (text: text, category: category)
        }
    }
}

enum ClassifierError: Error {
    case modelNotFound
    case invalidInput
}

// Usage
let classifier = try TextClassifier(modelName: "EmailClassifier")
let (category, confidence) = try classifier.classify("Click here to win free money!")
print("Category: \(category)")
for (label, prob) in confidence.sorted(by: { $0.value > $1.value }) {
    print("  \(label): \(String(format: "%.3f", prob))")
}
```

### Lemmatization and Stemming

```swift
// ✅ Correct: Normalizing words for comparison
import NaturalLanguage

func normalizeText(_ text: String) -> [String] {
    let tagger = NLTagger(tagSchemes: [.lemma])
    tagger.string = text
    
    var lemmas: [String] = []
    
    tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma) { tag, range in
        let word = String(text[range])
        
        // Skip punctuation and short words
        if word.count < 2 {
            return true
        }
        
        if let lemma = tag {
            lemmas.append(lemma.rawValue.lowercased())
        } else {
            lemmas.append(word.lowercased())
        }
        
        return true
    }
    
    return lemmas
}

// Usage
let normalized = normalizeText("The users are running and jumping through fields")
print(normalized)
// Output: ["the", "user", "be", "run", "and", "jump", "through", "field"]
```

---

## ✅ Best Practices

### Practice 1: Language-Aware Processing
**DO:**
```swift
// Detect language first, then process appropriately
let recognizer = NLLanguageRecognizer()
recognizer.processString(userText)

if let language = recognizer.dominantLanguage {
    let tagger = NLTagger(tagSchemes: [.posTag, .lemma])
    tagger.language = language  // Set correct language
    tagger.string = userText
}
```

### Practice 2: Batch Processing for Performance
**DO:**
```swift
// Process multiple items efficiently
func analyzeBatch(_ texts: [String]) {
    let tagger = NLTagger(tagSchemes: [.posTag])
    
    for text in texts {
        tagger.string = text
        // Process without recreating tagger each time
    }
}
```

### Practice 3: Cache Taggers for Repeated Use
**DO:**
```swift
class TextAnalyzer {
    private let tagger = NLTagger(tagSchemes: [.posTag, .lemma, .nameType])
    
    func analyze(_ text: String) {
        tagger.string = text  // Reuse same tagger
        // Process...
    }
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Processing Without Language Detection
**WRONG:**
```swift
// Assuming text is in English without checking
let tagger = NLTagger(tagSchemes: [.posTag])
tagger.string = userText  // Might be Spanish, Chinese, etc.
// Results will be inaccurate for non-English text
```

**CORRECT:**
```swift
let recognizer = NLLanguageRecognizer()
recognizer.processString(userText)

let tagger = NLTagger(tagSchemes: [.posTag])
tagger.language = recognizer.dominantLanguage
tagger.string = userText
```

### Mistake 2: Creating New Taggers for Each Operation
**WRONG:**
```swift
func processTexts(_ texts: [String]) {
    for text in texts {
        let tagger = NLTagger(tagSchemes: [.posTag])  // ❌ Inefficient
        tagger.string = text
        // Process...
    }
}
```

**CORRECT:**
```swift
func processTexts(_ texts: [String]) {
    let tagger = NLTagger(tagSchemes: [.posTag])  // ✅ Reuse
    for text in texts {
        tagger.string = text
        // Process...
    }
}
```

### Mistake 3: Ignoring Encoding Issues
**WRONG:**
```swift
// Not handling Unicode properly
let text = userInput
let tagger = NLTagger(tagSchemes: [.nameType])
tagger.string = text  // Emoji and special chars may not process correctly
```

**CORRECT:**
```swift
// Normalize Unicode before processing
import Foundation

let text = userInput.precomposedWithCompatibilityMapping
let tagger = NLTagger(tagSchemes: [.nameType])
tagger.string = text
```

### Mistake 4: Using Synchronous Processing on Main Thread
**WRONG:**
```swift
// Blocking UI during heavy NLP operations
@IBAction func analyzeButtonTapped() {
    let tagger = NLTagger(tagSchemes: [.posTag, .lemma, .nameType])
    tagger.string = largeText  // ❌ Blocks UI
    // Process...
}
```

**CORRECT:**
```swift
@IBAction func analyzeButtonTapped() {
    DispatchQueue.global(qos: .userInitiated).async {
        let tagger = NLTagger(tagSchemes: [.posTag, .lemma, .nameType])
        tagger.string = largeText
        // Process...
        
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
}
```

---

## 🔗 Related Topics
- [Vision Framework and ML](vision-and-machine-learning.md) - Computer vision and image analysis
- [Core ML Integration](../06-data/core-ml-models.md) - Machine learning models
- [Async Concurrency](async-concurrency.md) - Background processing
- [Text Handling](../01-fundamentals/strings-and-characters.md) - String manipulation
- [Performance Optimization](performance-optimization.md) - Optimizing NLP operations
