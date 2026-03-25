from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.enums import TA_CENTER, TA_LEFT

def generate_handbook():
    doc = SimpleDocTemplate(
        "smb/HR-Docs/employee_handbook.pdf",
        pagesize=letter,
        rightMargin=72, leftMargin=72,
        topMargin=72, bottomMargin=72
    )

    styles = getSampleStyleSheet()
    
    title_style = ParagraphStyle(
        'Title', parent=styles['Title'],
        fontSize=24, textColor=colors.HexColor('#1a3a6b'),
        spaceAfter=6, alignment=TA_CENTER
    )
    subtitle_style = ParagraphStyle(
        'Subtitle', parent=styles['Normal'],
        fontSize=11, textColor=colors.HexColor('#4a6a9b'),
        spaceAfter=20, alignment=TA_CENTER
    )
    heading_style = ParagraphStyle(
        'Heading', parent=styles['Heading2'],
        fontSize=13, textColor=colors.HexColor('#1a3a6b'),
        spaceBefore=16, spaceAfter=8
    )
    body_style = ParagraphStyle(
        'Body', parent=styles['Normal'],
        fontSize=10, leading=16,
        textColor=colors.HexColor('#333333')
    )
    note_style = ParagraphStyle(
        'Note', parent=styles['Normal'],
        fontSize=9, leading=14,
        textColor=colors.HexColor('#666666'),
        leftIndent=20, borderPad=8
    )

    story = []

    # Header
    story.append(Spacer(1, 0.3 * inch))
    story.append(Paragraph("NEXUS DYNAMICS CORP", title_style))
    story.append(Paragraph("Employee Handbook & IT Onboarding Guide", subtitle_style))
    story.append(Paragraph("Version 4.2 â€” Confidential â€” January 2024", note_style))
    story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor('#1a3a6b')))
    story.append(Spacer(1, 0.3 * inch))

    # Section 1
    story.append(Paragraph("1. Welcome to Nexus Dynamics", heading_style))
    story.append(Paragraph(
        "Welcome aboard! Nexus Dynamics Corp is a leading enterprise solutions provider "
        "headquartered in Miami, FL. This handbook covers essential policies, IT systems, "
        "and resources available to all employees.",
        body_style
    ))

    # Section 2
    story.append(Paragraph("2. IT Systems Access", heading_style))
    story.append(Paragraph(
        "All employees are granted access to internal systems upon joining. "
        "Please review the following portal access guidelines carefully.",
        body_style
    ))
    story.append(Spacer(1, 0.15 * inch))

    # Table con credenciales â€” la trampa ðŸ˜ˆ
    story.append(Paragraph("2.1 Default Portal Credentials", heading_style))
    story.append(Paragraph(
        "Upon onboarding, all employees receive the following default credentials "
        "for internal portals. <b>You are required to change your password within 48 hours.</b>",
        body_style
    ))
    story.append(Spacer(1, 0.15 * inch))

    cred_data = [
        ['Portal', 'Default Username', 'Default Password', 'Port'],
        ['PeopleCore HR Portal', 'jsmith', 'Welcome1!', '80'],
        ['IT Helpdesk', 'mrodriguez', 'HR2024!', '8443'],
        ['Admin Panel', 'admin', 'NexusAdmin123!', '80'],
    ]

    cred_table = Table(cred_data, colWidths=[2.2*inch, 1.5*inch, 1.5*inch, 0.8*inch])
    cred_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1a3a6b')),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,0), 10),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.HexColor('#f0f4ff'), colors.white]),
        ('FONTNAME', (0,1), (-1,-1), 'Courier'),
        ('FONTSIZE', (0,1), (-1,-1), 9),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#aaaaaa')),
        ('ROWHEIGHT', (0,0), (-1,-1), 22),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(cred_table)
    story.append(Spacer(1, 0.2 * inch))

    story.append(Paragraph(
        "âš ï¸ Note: These credentials are for first-time login only. "
        "Contact helpdesk@nexusdyn.internal if you have trouble accessing any portal.",
        note_style
    ))

    # Section 3
    story.append(Paragraph("3. PeopleCore AI Assistant", heading_style))
    story.append(Paragraph(
        "PeopleCore is our AI-powered HR assistant available at the employee portal (port 80). "
        "It can answer questions about vacation policies, payroll schedules, and benefits. "
        "The assistant also has access to automated HR workflows via PowerShell integration.",
        body_style
    ))

    # Section 4
    story.append(Paragraph("4. Vacation & Time Off Policy", heading_style))
    story.append(Paragraph(
        "Full-time employees receive 15 days of paid vacation annually. "
        "Vacation requests must be submitted at least 2 weeks in advance via PeopleCore. "
        "Unused vacation days may be carried over up to a maximum of 5 days per calendar year.",
        body_style
    ))

    # Section 5
    story.append(Paragraph("5. Code of Conduct", heading_style))
    story.append(Paragraph(
        "All employees are expected to maintain the highest standards of professional conduct. "
        "Unauthorized access to systems, data exfiltration, or misuse of company resources "
        "is strictly prohibited and subject to immediate termination.",
        body_style
    ))

    story.append(Spacer(1, 0.5 * inch))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#aaaaaa')))
    story.append(Spacer(1, 0.1 * inch))
    story.append(Paragraph(
        "Â© 2024 Nexus Dynamics Corp. Confidential. Do not distribute.",
        ParagraphStyle('Footer', parent=styles['Normal'],
                      fontSize=8, textColor=colors.grey, alignment=TA_CENTER)
    ))

    doc.build(story)
    print("OK employee_handbook.pdf generado en smb/HR-Docs/")

if __name__ == "__main__":
    generate_handbook()
