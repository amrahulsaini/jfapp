const nodemailer = require('nodemailer');

// Create reusable transporter
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false, // use STARTTLS
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD
    }
});

// Verify transporter configuration
transporter.verify((error, success) => {
    if (error) {
        console.error('Email transporter error:', error);
    } else {
        console.log('Email server is ready to send messages');
    }
});

/**
 * Send OTP email to user
 * @param {string} email - Recipient email address
 * @param {string} otp - 6-digit OTP code
 * @returns {Promise<Object>} - Email send result
 */
async function sendOTPEmail(email, otp) {
    const mailOptions = {
        from: `"JF Foundation" <${process.env.SMTP_USER}>`,
        to: email,
        subject: 'Your OTP for JF Foundation App',
        html: `
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body { font-family: 'Poppins', Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }
                    .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                    .header { background-color: #000000; padding: 30px; text-align: center; }
                    .header h1 { color: #ffffff; margin: 0; font-size: 24px; }
                    .content { padding: 40px 30px; }
                    .otp-box { background-color: #FF6B35; color: #ffffff; font-size: 32px; font-weight: bold; text-align: center; padding: 20px; border-radius: 8px; letter-spacing: 8px; margin: 30px 0; }
                    .message { color: #333333; line-height: 1.6; margin-bottom: 20px; }
                    .warning { background-color: #fff3cd; border-left: 4px solid #FF6B35; padding: 15px; margin: 20px 0; color: #856404; }
                    .footer { background-color: #f8f9fa; padding: 20px; text-align: center; color: #6c757d; font-size: 12px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>JF FOUNDATION</h1>
                    </div>
                    <div class="content">
                        <p class="message">Hello,</p>
                        <p class="message">You requested to sign in to the JF Foundation App. Use the following One-Time Password (OTP) to complete your verification:</p>
                        <div class="otp-box">${otp}</div>
                        <div class="warning">
                            <strong>⚠️ Security Notice:</strong><br>
                            • This OTP is valid for ${process.env.OTP_EXPIRY_MINUTES || 10} minutes only<br>
                            • Do not share this code with anyone<br>
                            • If you didn't request this, please ignore this email
                        </div>
                        <p class="message">If you're having trouble signing in, please contact support.</p>
                    </div>
                    <div class="footer">
                        <p>© 2024 JF Foundation. All rights reserved.</p>
                        <p>This is an automated email. Please do not reply.</p>
                    </div>
                </div>
            </body>
            </html>
        `,
        text: `Your OTP for JF Foundation App is: ${otp}\n\nThis OTP is valid for ${process.env.OTP_EXPIRY_MINUTES || 10} minutes.\n\nDo not share this code with anyone.\n\nIf you didn't request this, please ignore this email.`
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log('OTP email sent:', info.messageId);
        return { success: true, messageId: info.messageId };
    } catch (error) {
        console.error('Error sending OTP email:', error);
        throw new Error('Failed to send OTP email');
    }
}

module.exports = {
    sendOTPEmail
};
