#!/usr/bin/env python3
"""
Debug script to test LinkedIn extraction service
Run this to verify extraction is working correctly
"""

from linkedin_extractor import extract_from_html

# Test 1: Simple skill extraction
test_html_1 = """
<html>
<body>
    <h2>Skills</h2>
    <div class="skill">Python</div>
    <div class="skill">Flutter</div>
    <div class="skill">React</div>
    <div class="skill">JavaScript</div>
</body>
</html>
"""

print("=" * 60)
print("Test 1: Simple skill-based HTML")
print("=" * 60)
result = extract_from_html(test_html_1)
print(f"Skills found: {result['skills']}")
print(f"Experience found: {result['experience']}")
print()

# Test 2: Real-world-like LinkedIn snippet
test_html_2 = """
<html>
<body>
    <section>
        <h2>Experience</h2>
        <div class="experience-item">
            <div class="title">Senior Developer</div>
            <div class="company">at Tech Corporation</div>
            <div class="duration">Jan 2021 - Present</div>
        </div>
        <div class="experience-item">
            <div class="title">Junior Engineer</div>
            <div class="company">at StartUp Inc</div>
            <div class="duration">Jun 2019 - Dec 2020</div>
        </div>
    </section>
    
    <section>
        <h2>Skills</h2>
        <span>Python</span>
        <span>JavaScript</span>
        <span>React</span>
        <span>Flutter</span>
        <span>SQL</span>
        <span>Docker</span>
    </section>
</body>
</html>
"""

print("=" * 60)
print("Test 2: Real-world-like LinkedIn profile")
print("=" * 60)
result = extract_from_html(test_html_2)
print(f"Skills found ({len(result['skills'])}): {result['skills']}")
print(f"Experience found ({len(result['experience'])}): {result['experience']}")
print()

# Test 3: Complex nested HTML
test_html_3 = """
<html>
<head><title>LinkedIn Profile</title></head>
<body>
    <div class="profile">
        <h1>John Developer</h1>
        
        <article class="experiences">
            <h2>Experience</h2>
            <div class="experience">
                <h3>Software Engineer at Google</h3>
                <p>January 2020 - Present</p>
                <p>Led team of 5 developers. Worked with Python, JavaScript</p>
            </div>
            <div class="experience">
                <h3>Junior Developer at Facebook</h3>
                <p>June 2018 - December 2019</p>
                <p>Built React components</p>
            </div>
        </article>
        
        <article class="skills">
            <h2>Skills & Expertise</h2>
            <div class="skill-item">Python</div>
            <div class="skill-item">JavaScript</div>
            <div class="skill-item">React</div>
            <div class="skill-item">Flutter</div>
            <div class="skill-item">Django</div>
            <div class="skill-item">FastAPI</div>
            <div class="skill-item">AWS</div>
            <div class="skill-item">Docker</div>
        </article>
    </div>
</body>
</html>
"""

print("=" * 60)
print("Test 3: Complex nested LinkedIn-like HTML")
print("=" * 60)
result = extract_from_html(test_html_3)
print(f"Skills found ({len(result['skills'])}): {result['skills']}")
print(f"Experience found ({len(result['experience'])}):")
for i, exp in enumerate(result['experience'], 1):
    print(f"  {i}. {exp['role_company']} | {exp['duration']}")
print()

# Test 4: Minimal HTML with just skills mentioned
test_html_4 = """
<html>
<body>
    I have experience with Python, JavaScript, React, and Flutter.
    I'm skilled in AWS, Docker, and Kubernetes.
    I've worked with PostgreSQL and MongoDB databases.
</body>
</html>
"""

print("=" * 60)
print("Test 4: Plain text with technical skills")
print("=" * 60)
result = extract_from_html(test_html_4)
print(f"Skills found ({len(result['skills'])}): {result['skills']}")
print(f"Experience found: {result['experience']}")
print()

# Test 5: User's actual LinkedIn HTML snippet
test_html_5 = """
<html>
<body>
    <div>
        <h2>Abdul Samad</h2>
        <h3>Software Engineer</h3>
        
        <section id="experience">
            <h4>Experience</h4>
            <div class="position">
                Senior Software Engineer at Tech Solutions Ltd
                Jan 2022 - Present
            </div>
            <div class="position">
                Full Stack Developer at Digital Innovations
                Jun 2020 - Dec 2021
            </div>
        </section>
        
        <section id="skills">
            <h4>Skills</h4>
            Flutter Development
            React Development
            Python Programming
            JavaScript
            UI/UX Design
            Project Management
            Leadership
        </section>
    </div>
</body>
</html>
"""

print("=" * 60)
print("Test 5: Sample realistic profile")
print("=" * 60)
result = extract_from_html(test_html_5)
print(f"Skills found ({len(result['skills'])}): {result['skills']}")
print(f"Experience found ({len(result['experience'])}):")
for i, exp in enumerate(result['experience'], 1):
    print(f"  {i}. {exp['role_company']} | {exp['duration']}")
print()

# Summary
print("=" * 60)
print("EXTRACTION SUMMARY")
print("=" * 60)
print("✅ If you see skills and experience above, extraction is working!")
print("✅ Copy your actual LinkedIn HTML and test with it")
print("✅ Check backend logs for detailed debug information")
print()
print("NEXT STEPS:")
print("1. Run: python main.py")
print("2. Send your LinkedIn HTML to: POST /linkedin/extract/html")
print("3. For debugging: POST /debug/extract-html")
print()
