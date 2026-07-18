from fpdf import FPDF
import arabic_reshaper
from bidi.algorithm import get_display

def write_arabic_multicell(pdf, text, max_width=0, line_height=8):
    if max_width == 0:
        max_width = pdf.w - pdf.l_margin - pdf.r_margin

    paragraphs = text.split('\n')
    for p in paragraphs:
        if not p.strip():
            pdf.ln(line_height)
            continue
            
        reshaped_p = arabic_reshaper.reshape(p)
        words = reshaped_p.split(' ')
        line = ""
        
        for word in words:
            if line == "":
                test_line = word
            else:
                test_line = line + " " + word
                
            if pdf.get_string_width(test_line) <= max_width:
                line = test_line
            else:
                bidi_line = get_display(line)
                pdf.cell(max_width, line_height, bidi_line, align='R', new_x="LMARGIN", new_y="NEXT")
                line = word
                
        if line:
            bidi_line = get_display(line)
            pdf.cell(max_width, line_height, bidi_line, align='R', new_x="LMARGIN", new_y="NEXT")

