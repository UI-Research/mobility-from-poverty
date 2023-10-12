# **Git Training: Pre-Training Git and GitHub Access Checklist for Mobility Metrics Data Team**

This guide will walk through the steps to ensure that you have access to Git and Github. For those that are active users this will not apply to you.

## Setting up a GitHub account and installing Git software 

### Returning Contributers 

Please make sure you still have access to your GitHub account. You can check this navigating to https://github.com/ and checking if you still can view the [mobility-from-poverty](https://github.com/UI-Research/mobility-from-poverty) project repository page. If you cannot access the repository, please email me at jwalsh@urban.org describing the issue. 

Please check if Git is downloaded on your computer. Reminder, if Git is downloaded you should see an option to “Open Git Bash here” when you left click in any folder on your computer. If Git is not installed on your current computer, please install it from the following website.  

If you still have the mobility-from-poverty repository cloned to your local computer, please delete that folder. We will be re-cloning the latest version of the repository from GItHub during this training.  

 
### New Contributors

If you have not so already, please create a [GitHub](https://github.com/) account.  

After creating the github account ask, them to fill out the Urban GitHub [intake form](https://app.smartsheet.com/b/form/9f0c5ba330dd4b73980fe5a6e17216b5) requesting access to UI Research. After recieving access you should be able to access the [mobility-from-poverty](https://github.com/UI-Research/mobility-from-poverty) project repository page. 

If you have not already installed the Git software, please complete the installation process from the following [website](https://git-scm.com/downloads). You will know it installed successfully if upon completion when you left click in any folder on your computer you see an option to “Open Git Bash here”. 

## Configuring Git and Github to your account and email

Open git bash on your computers (does not matter where you do it we are just checking that Git is aligned with your Github account)

For returning contributors/existing git users, check if you are configured with the following commands. First we can check if the correct email is synced with git bash.

```{bash}
git config --get user.email
```

Next, let's check if our GitHub account is synced by checking the username configured with Git.

```{bash}
git config --get user.name
```

After entering the two commands above in GitBash, you should see your Github username and Urban email listed in the output.

If you are a new contributors/git user or an returning user and you do not see the right email or username use the following command to configure your Git:

```{bash}
git config --global user.name "<your_github_username>"
git config --global user.email "<your_email_address>"
```

*Note the "<" in the above command are just to indicate that you should insert your own text, you should not include them in the command line.*

## Authentication and tokens

Create authentication tokens for those who do not have them. You will need to create a personal access token (PAT) to replace your password and provide enhanced security. [Since 2021](https://github.blog/2020-12-15-token-authentication-requirements-for-git-operations/), GitHub has required PATs to perform Git operations. To create a PAT:

1.  Log into your [GitHub account](https://github.com/). Navigate to the drop-down menu in the top right corner with your profile picture. Select **Settings** near the bottom of this drop-down.

2.  From your account settings, navigate to **Developer Settings**, at the bottom of the menu on the left.

3.  From the developer settings, navigate to **Personal Access Tokens** in the menu on the left.

4.  Click **Generate new token (classic)**. You may be prompted to re-enter your GitHub password.

5.  Add a note to label the token. This is useful if you intend to generate multiple tokens for different uses. Then, set a time limit for the token -- you can set this to never expire. Finally, select the scope of permissions you would like to give the token - you can select all all options. Then click **Generate token**.

6.  The generated token will appear. **Make sure to copy and safely store the token when it appears, as you will not be able to view it again.** Note that if you lose your token, you can always generate a new one. Use this in place of your GitHub password when prompted by Git (or when using the GitHub API).

The first time you attempt to clone (copy to your computer) a repository that is private on GitHub, Git will prompt you for your credentials. Your username is just your GitHub username. Your password should be the PAT that you created. *Note: the cursor in Git Bash will not move when adding your PAT.*